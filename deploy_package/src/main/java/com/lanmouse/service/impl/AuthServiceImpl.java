package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.dto.*;
import com.lanmouse.entity.User;
import com.lanmouse.entity.UserGroup;
import com.lanmouse.mapper.UserGroupMapper;
import com.lanmouse.mapper.UserMapper;
import com.lanmouse.service.AuthService;
import com.lanmouse.service.WechatService;
import com.lanmouse.util.IdCardValidator;
import com.lanmouse.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthServiceImpl implements AuthService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private UserGroupMapper userGroupMapper;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private WechatService wechatService;

    @Override
    public LoginResponse register(RegisterRequest request) {
        // 校验身份证号
        if (!IdCardValidator.isValid(request.getIdCard())) {
            throw new IllegalArgumentException("身份证号格式不合法");
        }

        // 检查手机号是否已注册
        LambdaQueryWrapper<User> phoneWrapper = new LambdaQueryWrapper<>();
        phoneWrapper.eq(User::getPhone, request.getPhone());
        if (userMapper.selectCount(phoneWrapper) > 0) {
            throw new IllegalArgumentException("手机号已被注册");
        }

        // 检查身份证号是否已注册
        String idCardHash = IdCardValidator.hashIdCard(request.getIdCard());
        LambdaQueryWrapper<User> idCardWrapper = new LambdaQueryWrapper<>();
        idCardWrapper.eq(User::getIdCardHash, idCardHash);
        if (userMapper.selectCount(idCardWrapper) > 0) {
            throw new IllegalArgumentException("身份证号已被注册");
        }

        // 获取默认用户组
        LambdaQueryWrapper<UserGroup> groupWrapper = new LambdaQueryWrapper<>();
        groupWrapper.eq(UserGroup::getCode, "NORMAL");
        groupWrapper.eq(UserGroup::getStatus, 1);
        UserGroup userGroup = userGroupMapper.selectOne(groupWrapper);
        if (userGroup == null) {
            userGroup = new UserGroup();
            userGroup.setId(1);
        }

        // 创建用户
        User user = new User();
        user.setPhone(request.getPhone());
        user.setName(request.getName());
        user.setIdCard(request.getIdCard());
        user.setIdCardHash(idCardHash);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setUserGroupId(userGroup.getId());
        user.setStatus(1);

        userMapper.insert(user);

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getPhone());

        // 构建响应
        LoginResponse response = new LoginResponse();
        response.setUserId(user.getId());
        response.setToken(token);
        response.setMaskedIdCard(IdCardValidator.maskIdCard(request.getIdCard()));
        response.setName(user.getName());

        LoginResponse.UserGroupInfo userGroupInfo = new LoginResponse.UserGroupInfo();
        userGroupInfo.setId(userGroup.getId());
        userGroupInfo.setName(userGroup.getName());
        userGroupInfo.setAnnualFee(userGroup.getAnnualFee().toString());
        response.setUserGroup(userGroupInfo);

        return response;
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        // 查询用户
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getPhone, request.getPhone());
        User user = userMapper.selectOne(wrapper);

        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        if (user.getStatus() != 1) {
            throw new IllegalArgumentException("用户已被禁用");
        }

        // 验证密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("密码错误");
        }

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getPhone());

        // 获取用户组
        UserGroup userGroup = userGroupMapper.selectById(user.getUserGroupId());

        // 构建响应
        LoginResponse response = new LoginResponse();
        response.setUserId(user.getId());
        response.setToken(token);
        response.setMaskedIdCard(IdCardValidator.maskIdCard(user.getIdCard()));
        response.setName(user.getName());

        if (userGroup != null) {
            LoginResponse.UserGroupInfo userGroupInfo = new LoginResponse.UserGroupInfo();
            userGroupInfo.setId(userGroup.getId());
            userGroupInfo.setName(userGroup.getName());
            userGroupInfo.setAnnualFee(userGroup.getAnnualFee().toString());
            response.setUserGroup(userGroupInfo);
        }

        return response;
    }

    @Override
    public String refreshToken(String refreshToken) {
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("刷新Token无效");
        }

        Long userId = jwtUtil.getUserIdFromToken(refreshToken);
        User user = userMapper.selectById(userId);

        if (user == null || user.getStatus() != 1) {
            throw new IllegalArgumentException("用户不存在或已被禁用");
        }

        return jwtUtil.generateToken(user.getId(), user.getPhone());
    }

    @Override
    public LoginResponse wechatLogin(WechatLoginRequest request) {
        // 获取openid
        String openid = wechatService.getOpenid(request.getCode());

        // 查询是否已存在该openid的用户
        LambdaQueryWrapper<User> openidWrapper = new LambdaQueryWrapper<>();
        openidWrapper.eq(User::getOpenid, openid);
        User user = userMapper.selectOne(openidWrapper);

        boolean isNewUser = false;

        if (user == null) {
            // 新用户，自动注册
            isNewUser = true;

            // 获取默认用户组
            LambdaQueryWrapper<UserGroup> groupWrapper = new LambdaQueryWrapper<>();
            groupWrapper.eq(UserGroup::getCode, "NORMAL");
            groupWrapper.eq(UserGroup::getStatus, 1);
            UserGroup userGroup = userGroupMapper.selectOne(groupWrapper);
            if (userGroup == null) {
                userGroup = new UserGroup();
                userGroup.setId(1);
            }

            // 创建用户
            user = new User();
            user.setOpenid(openid);
            user.setName(request.getNickname() != null ? request.getNickname() : "微信用户");
            user.setUserGroupId(userGroup.getId());
            user.setStatus(1);

            // 如果提供了手机号，设置手机号
            if (request.getPhone() != null && !request.getPhone().isEmpty()) {
                user.setPhone(request.getPhone());
            }

            userMapper.insert(user);
        } else {
            // 老用户，检查状态
            if (user.getStatus() != 1) {
                throw new IllegalArgumentException("用户已被禁用");
            }

            // 更新昵称
            if (request.getNickname() != null) {
                user.setName(request.getNickname());
            }
            userMapper.updateById(user);
        }

        // 生成Token
        String token = jwtUtil.generateToken(user.getId(), user.getPhone());

        // 获取用户组
        UserGroup userGroup = userGroupMapper.selectById(user.getUserGroupId());

        // 构建响应
        LoginResponse response = new LoginResponse();
        response.setUserId(user.getId());
        response.setToken(token);
        response.setMaskedIdCard(user.getIdCard() != null ? IdCardValidator.maskIdCard(user.getIdCard()) : null);
        response.setName(user.getName());
        response.setNewUser(isNewUser);

        if (userGroup != null) {
            LoginResponse.UserGroupInfo userGroupInfo = new LoginResponse.UserGroupInfo();
            userGroupInfo.setId(userGroup.getId());
            userGroupInfo.setName(userGroup.getName());
            userGroupInfo.setAnnualFee(userGroup.getAnnualFee() != null ? userGroup.getAnnualFee().toString() : "0");
            response.setUserGroup(userGroupInfo);
        }

        return response;
    }
}
