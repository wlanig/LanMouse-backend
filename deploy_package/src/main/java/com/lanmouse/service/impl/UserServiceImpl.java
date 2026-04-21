package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.entity.User;
import com.lanmouse.entity.UserGroup;
import com.lanmouse.mapper.UserMapper;
import com.lanmouse.mapper.UserGroupMapper;
import com.lanmouse.service.UserService;
import com.lanmouse.dto.RegisterRequest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 用户服务实现
 */
@Service
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;
    private final UserGroupMapper userGroupMapper;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserServiceImpl(UserMapper userMapper, UserGroupMapper userGroupMapper, BCryptPasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.userGroupMapper = userGroupMapper;
        this.passwordEncoder = passwordEncoder;
    }

    // 身份证号权重
    private static final int[] WEIGHT = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
    private static final char[] CHECK_CODE = {'1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'};

    // 身份证地区码（部分）
    private static final String[] REGION_CODES = {
        "11", "12", "13", "14", "15", "21", "22", "23", "31", "32", "33", "34", "35", "36", "37",
        "41", "42", "43", "44", "45", "46", "50", "51", "52", "53", "54", "61", "62", "63", "64", "65"
    };

    @Override
    public User register(RegisterRequest request) {
        User user = new User();
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setName(request.getName());
        user.setIdCard(encryptIdCard(request.getIdCard()));
        user.setIdCardHash(hashIdCard(request.getIdCard()));
        user.setUserGroupId(1); // 默认普通用户组
        user.setStatus(1);

        userMapper.insert(user);
        return user;
    }

    @Override
    public User findByPhone(String phone) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getPhone, phone);
        return userMapper.selectOne(wrapper);
    }

    @Override
    public User findById(Long id) {
        return userMapper.selectById(id);
    }

    @Override
    public boolean existsByPhone(String phone) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getPhone, phone);
        return userMapper.selectCount(wrapper) > 0;
    }

    @Override
    public boolean existsByIdCard(String idCard) {
        String hash = hashIdCard(idCard);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getIdCardHash, hash);
        return userMapper.selectCount(wrapper) > 0;
    }

    @Override
    public boolean verifyPassword(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Override
    public boolean validateIdCard(String idCard) {
        if (idCard == null || !Pattern.matches("^\\d{17}[\\dXx]$", idCard)) {
            return false;
        }

        // 验证地区码
        String regionCode = idCard.substring(0, 2);
        boolean validRegion = false;
        for (String code : REGION_CODES) {
            if (code.equals(regionCode)) {
                validRegion = true;
                break;
            }
        }
        if (!validRegion) {
            return false;
        }

        // 验证出生日期
        String birthDate = idCard.substring(6, 14);
        if (!isValidDate(birthDate)) {
            return false;
        }

        // 验证校验码
        return validateCheckCode(idCard);
    }

    /**
     * 验证身份证校验码
     */
    private boolean validateCheckCode(String idCard) {
        int sum = 0;
        for (int i = 0; i < 17; i++) {
            sum += Character.getNumericValue(idCard.charAt(i)) * WEIGHT[i];
        }
        int index = sum % 11;
        char checkCode = CHECK_CODE[index];
        char lastChar = Character.toUpperCase(idCard.charAt(17));
        return checkCode == lastChar;
    }

    /**
     * 验证日期是否有效
     */
    private boolean isValidDate(String date) {
        try {
            int year = Integer.parseInt(date.substring(0, 4));
            int month = Integer.parseInt(date.substring(4, 6));
            int day = Integer.parseInt(date.substring(6, 8));

            if (year < 1900 || year > 2100) return false;
            if (month < 1 || month > 12) return false;
            if (day < 1 || day > 31) return false;

            // 简单月份天数验证
            int[] daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
            if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
                daysInMonth[1] = 29;
            }
            return day <= daysInMonth[month - 1];
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 加密身份证号（简单XOR加密，实际应使用更安全的方式）
     */
    private String encryptIdCard(String idCard) {
        // 实际生产环境应使用AES等加密算法
        return idCard;
    }

    /**
     * 计算身份证号哈希
     */
    private String hashIdCard(String idCard) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((idCard + "lanmouse_salt").getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }

    @Override
    public Map<String, Object> getUserGroupInfo(Integer userGroupId) {
        UserGroup group = userGroupMapper.selectById(userGroupId);
        Map<String, Object> info = new HashMap<>();
        if (group != null) {
            info.put("id", group.getId());
            info.put("name", group.getName());
            info.put("annualFee", group.getAnnualFee());
            info.put("discountRate", group.getDiscountRate());
        }
        return info;
    }
}
