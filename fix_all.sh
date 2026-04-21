#!/bin/bash
# 完整修复脚本

cd /opt/lanmouse

# 1. 修复文件名问题
mv src/main/java/com/lanmouse/config/CorsConfig.java src/main/java/com/lanmouse/config/WebConfig.java 2>/dev/null
mv src/main/java/com/lanmouse/config/JwtConfig.java src/main/java/com/lanmouse/config/SecurityConfig.java 2>/dev/null

# 2. 修复所有Service接口
mkdir -p src/main/java/com/lanmouse/service

# UserService接口
cat > src/main/java/com/lanmouse/service/UserService.java << 'EOF'
package com.lanmouse.service;

import com.lanmouse.dto.RegisterRequest;
import com.lanmouse.entity.User;

public interface UserService {
    User getUserById(Long id);
    User getUserByPhone(String phone);
    boolean registerUser(RegisterRequest request);
    boolean validatePassword(String rawPassword, String encodedPassword);
    String hashIdCard(String idCard);
}
EOF

# DeviceService接口
cat > src/main/java/com/lanmouse/service/DeviceService.java << 'EOF'
package com.lanmouse.service;

import com.lanmouse.dto.BindRequest;
import com.lanmouse.dto.DeviceRegisterRequest;
import com.lanmouse.dto.DeviceRegisterResponse;
import com.lanmouse.dto.DeviceListResponse;
import java.util.List;

public interface DeviceService {
    DeviceRegisterResponse registerDevice(Long userId, DeviceRegisterRequest request);
    void bindDevice(Long userId, BindRequest request);
    List<DeviceListResponse> getDeviceList(Long userId);
}
EOF

# AuthService接口
cat > src/main/java/com/lanmouse/service/AuthService.java << 'EOF'
package com.lanmouse.service;

import com.lanmouse.dto.LoginRequest;
import com.lanmouse.dto.LoginResponse;
import com.lanmouse.dto.RegisterRequest;

public interface AuthService {
    void register(RegisterRequest request);
    LoginResponse login(LoginRequest request);
    String refreshToken(String token);
}
EOF

# SubscriptionService接口
cat > src/main/java/com/lanmouse/service/SubscriptionService.java << 'EOF'
package com.lanmouse.service;

import com.lanmouse.dto.CreateOrderRequest;
import com.lanmouse.dto.CreateOrderResponse;
import com.lanmouse.dto.SubscriptionStatusResponse;

public interface SubscriptionService {
    CreateOrderResponse createOrder(Long userId, CreateOrderRequest request);
    SubscriptionStatusResponse getSubscriptionStatus(Long userId, Long deviceId);
    boolean verifySubscription(Long deviceId, String imei);
}
EOF

# 3. 修复所有ServiceImpl
mkdir -p src/main/java/com/lanmouse/service/impl

# UserServiceImpl
cat > src/main/java/com/lanmouse/service/impl/UserServiceImpl.java << 'EOF'
package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.entity.User;
import com.lanmouse.mapper.UserMapper;
import com.lanmouse.mapper.UserGroupMapper;
import com.lanmouse.service.UserService;
import com.lanmouse.dto.RegisterRequest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.regex.Pattern;

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

    @Override
    public User getUserById(Long id) {
        return userMapper.selectById(id);
    }

    @Override
    public User getUserByPhone(String phone) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(User::getPhone, phone);
        return userMapper.selectOne(wrapper);
    }

    @Override
    public boolean registerUser(RegisterRequest request) {
        if (!isValidIdCard(request.getIdCard())) {
            throw new RuntimeException("身份证号格式不正确");
        }
        if (getUserByPhone(request.getPhone()) != null) {
            throw new RuntimeException("手机号已注册");
        }
        User user = new User();
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setName(request.getName());
        user.setIdCardHash(hashIdCard(request.getIdCard()));
        user.setUserGroupId(1L);
        user.setStatus(1);
        return userMapper.insert(user) > 0;
    }

    @Override
    public boolean validatePassword(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Override
    public String hashIdCard(String idCard) {
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

    private boolean isValidIdCard(String idCard) {
        if (idCard == null || idCard.length() != 18) return false;
        String pattern = "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$";
        if (!Pattern.matches(pattern, idCard)) return false;
        int[] weights = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
        char[] checkCodes = {'1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'};
        int sum = 0;
        for (int i = 0; i < 17; i++) {
            sum += (idCard.charAt(i) - '0') * weights[i];
        }
        return checkCodes[sum % 11] == Character.toUpperCase(idCard.charAt(17));
    }
}
EOF

# DeviceServiceImpl
cat > src/main/java/com/lanmouse/service/impl/DeviceServiceImpl.java << 'EOF'
package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.entity.Device;
import com.lanmouse.mapper.DeviceMapper;
import com.lanmouse.service.DeviceService;
import com.lanmouse.dto.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DeviceServiceImpl implements DeviceService {

    private final DeviceMapper deviceMapper;

    public DeviceServiceImpl(DeviceMapper deviceMapper) {
        this.deviceMapper = deviceMapper;
    }

    @Override
    @Transactional
    public DeviceRegisterResponse registerDevice(Long userId, DeviceRegisterRequest request) {
        Device device = new Device();
        device.setUserId(userId);
        device.setImei1(request.getImei());
        device.setDeviceName(request.getDeviceName());
        device.setOsType(request.getOsType());
        device.setStatus(0);
        device.setCreateTime(LocalDateTime.now());
        device.setUpdateTime(LocalDateTime.now());
        deviceMapper.insert(device);

        DeviceRegisterResponse response = new DeviceRegisterResponse();
        response.setDeviceId(device.getId());
        response.setBindToken(UUID.randomUUID().toString().replace("-", "").substring(0, 16));
        response.setExpiresAt(LocalDateTime.now().plusHours(24));
        return response;
    }

    @Override
    @Transactional
    public void bindDevice(Long userId, BindRequest request) {
        Device device = deviceMapper.selectById(request.getDeviceId());
        if (device == null) throw new RuntimeException("设备不存在");
        if (device.getUserId() != null && !device.getUserId().equals(userId)) {
            throw new RuntimeException("设备已被其他用户绑定");
        }
        device.setUserId(userId);
        device.setStatus(1);
        device.setUpdateTime(LocalDateTime.now());
        deviceMapper.updateById(device);
    }

    @Override
    public List<DeviceListResponse> getDeviceList(Long userId) {
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Device::getUserId, userId);
        return deviceMapper.selectList(wrapper).stream().map(d -> {
            DeviceListResponse r = new DeviceListResponse();
            r.setDeviceId(d.getId());
            r.setDeviceName(d.getDeviceName());
            r.setOsType(d.getOsType());
            r.setStatus(d.getStatus());
            r.setCreateTime(d.getCreateTime());
            return r;
        }).collect(Collectors.toList());
    }
}
EOF

# AuthServiceImpl
cat > src/main/java/com/lanmouse/service/impl/AuthServiceImpl.java << 'EOF'
package com.lanmouse.service.impl;

import com.lanmouse.dto.LoginRequest;
import com.lanmouse.dto.LoginResponse;
import com.lanmouse.dto.RegisterRequest;
import com.lanmouse.entity.User;
import com.lanmouse.entity.UserGroup;
import com.lanmouse.mapper.UserMapper;
import com.lanmouse.mapper.UserGroupMapper;
import com.lanmouse.service.AuthService;
import com.lanmouse.util.JwtUtil;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserMapper userMapper;
    private final UserGroupMapper userGroupMapper;
    private final BCryptPasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthServiceImpl(UserMapper userMapper, UserGroupMapper userGroupMapper, 
                          BCryptPasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userMapper = userMapper;
        this.userGroupMapper = userGroupMapper;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @Override
    @Transactional
    public void register(RegisterRequest request) {
        if (!isValidIdCard(request.getIdCard())) {
            throw new RuntimeException("身份证号格式不正确");
        }
        if (userMapper.selectByPhone(request.getPhone()) != null) {
            throw new RuntimeException("手机号已注册");
        }
        User user = new User();
        user.setPhone(request.getPhone());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setName(request.getName());
        user.setIdCardHash(hashIdCard(request.getIdCard()));
        user.setUserGroupId(1L);
        user.setStatus(1);
        userMapper.insert(user);
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        User user = userMapper.selectByPhone(request.getPhone());
        if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("手机号或密码错误");
        }
        if (user.getStatus() != 1) throw new RuntimeException("账号已被禁用");

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("phone", user.getPhone());
        String token = jwtUtil.generateToken(claims);

        UserGroup userGroup = userGroupMapper.selectById(user.getUserGroupId());

        LoginResponse response = new LoginResponse();
        response.setToken(token);
        response.setExpireTime(System.currentTimeMillis() + 86400000);
        
        LoginResponse.UserInfo userInfo = new LoginResponse.UserInfo();
        userInfo.setId(user.getId());
        userInfo.setPhone(user.getPhone());
        userInfo.setName(user.getName());
        userInfo.setUserGroup(userGroup != null ? userGroup.getName() : "普通用户");
        response.setUser(userInfo);
        
        return response;
    }

    @Override
    public String refreshToken(String token) {
        if (!jwtUtil.validateToken(token)) throw new RuntimeException("Token无效");
        return jwtUtil.generateToken(jwtUtil.getClaimsFromToken(token));
    }

    private boolean isValidIdCard(String idCard) {
        if (idCard == null || idCard.length() != 18) return false;
        String pattern = "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$";
        if (!Pattern.matches(pattern, idCard)) return false;
        int[] weights = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};
        char[] checkCodes = {'1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'};
        int sum = 0;
        for (int i = 0; i < 17; i++) sum += (idCard.charAt(i) - '0') * weights[i];
        return checkCodes[sum % 11] == Character.toUpperCase(idCard.charAt(17));
    }

    private String hashIdCard(String idCard) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((idCard + "lanmouse_salt").getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 error", e);
        }
    }
}
EOF

# SubscriptionServiceImpl
cat > src/main/java/com/lanmouse/service/impl/SubscriptionServiceImpl.java << 'EOF'
package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.entity.Device;
import com.lanmouse.entity.PaymentQrCode;
import com.lanmouse.entity.Subscription;
import com.lanmouse.mapper.DeviceMapper;
import com.lanmouse.mapper.PaymentQrCodeMapper;
import com.lanmouse.mapper.SubscriptionMapper;
import com.lanmouse.service.SubscriptionService;
import com.lanmouse.dto.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class SubscriptionServiceImpl implements SubscriptionService {

    private final SubscriptionMapper subscriptionMapper;
    private final DeviceMapper deviceMapper;
    private final PaymentQrCodeMapper paymentQrCodeMapper;

    public SubscriptionServiceImpl(SubscriptionMapper subscriptionMapper, DeviceMapper deviceMapper, 
                                   PaymentQrCodeMapper paymentQrCodeMapper) {
        this.subscriptionMapper = subscriptionMapper;
        this.deviceMapper = deviceMapper;
        this.paymentQrCodeMapper = paymentQrCodeMapper;
    }

    @Override
    @Transactional
    public CreateOrderResponse createOrder(Long userId, CreateOrderRequest request) {
        Device device = deviceMapper.selectById(request.getDeviceId());
        if (device == null) throw new RuntimeException("设备不存在");

        String orderNo = "LM" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6);

        Subscription subscription = new Subscription();
        subscription.setUserId(userId);
        subscription.setDeviceId(request.getDeviceId());
        subscription.setOrderNo(orderNo);
        subscription.setAmount(request.getAmount());
        subscription.setPaymentStatus("pending");
        subscription.setCreateTime(LocalDateTime.now());
        subscriptionMapper.insert(subscription);

        PaymentQrCode qrCode = new PaymentQrCode();
        qrCode.setOrderNo(orderNo);
        qrCode.setQrCodeUrl("https://api.lanmouse.com/pay/qr/" + orderNo);
        qrCode.setExpiresAt(LocalDateTime.now().plusMinutes(30));
        qrCode.setStatus(0);
        paymentQrCodeMapper.insert(qrCode);

        CreateOrderResponse response = new CreateOrderResponse();
        response.setOrderNo(orderNo);
        response.setQrCodeUrl(qrCode.getQrCodeUrl());
        response.setAmount(request.getAmount());
        response.setExpiresAt(qrCode.getExpiresAt());
        return response;
    }

    @Override
    public SubscriptionStatusResponse getSubscriptionStatus(Long userId, Long deviceId) {
        LambdaQueryWrapper<Subscription> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Subscription::getDeviceId, deviceId)
               .eq(Subscription::getPaymentStatus, "paid")
               .ge(Subscription::getEndDate, LocalDate.now())
               .orderByDesc(Subscription::getEndDate)
               .last("LIMIT 1");
        Subscription sub = subscriptionMapper.selectOne(wrapper);

        SubscriptionStatusResponse response = new SubscriptionStatusResponse();
        if (sub != null) {
            response.setActive(true);
            response.setStartDate(sub.getStartDate());
            response.setEndDate(sub.getEndDate());
            response.setDaysRemaining((int) (sub.getEndDate().toEpochDay() - LocalDate.now().toEpochDay()));
        } else {
            response.setActive(false);
            response.setDaysRemaining(0);
        }
        return response;
    }

    @Override
    public boolean verifySubscription(Long deviceId, String imei) {
        LambdaQueryWrapper<Device> dw = new LambdaQueryWrapper<>();
        dw.eq(Device::getId, deviceId);
        if (imei != null) dw.eq(Device::getImei1, imei);
        Device device = deviceMapper.selectOne(dw);
        if (device == null) return false;

        LambdaQueryWrapper<Subscription> sw = new LambdaQueryWrapper<>();
        sw.eq(Subscription::getDeviceId, deviceId)
          .eq(Subscription::getPaymentStatus, "paid")
          .ge(Subscription::getEndDate, LocalDate.now());
        return subscriptionMapper.selectCount(sw) > 0;
    }
}
EOF

echo "所有Service文件已修复"

# 4. 重新编译
echo "开始编译..."
mvn clean package -DskipTests -q

if [ $? -eq 0 ]; then
    echo "编译成功！"
else
    echo "编译失败，查看详细错误:"
    mvn clean compile 2>&1 | tail -50
fi
