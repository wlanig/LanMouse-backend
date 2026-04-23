package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.lanmouse.dto.*;
import com.lanmouse.entity.*;
import com.lanmouse.mapper.*;
import com.lanmouse.service.AdminService;
import com.lanmouse.util.IdCardValidator;
import com.lanmouse.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
public class AdminServiceImpl implements AdminService {

    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final UserGroupMapper userGroupMapper;
    private final DeviceMapper deviceMapper;
    private final SubscriptionMapper subscriptionMapper;
    private final PaymentQrCodeMapper paymentQrCodeMapper;

    @Value("${admin.username:admin}")
    private String adminUsername;

    @Value("${admin.password}")
    private String adminPassword;

    public AdminServiceImpl(JwtUtil jwtUtil, BCryptPasswordEncoder passwordEncoder,
                            UserMapper userMapper, UserGroupMapper userGroupMapper,
                            DeviceMapper deviceMapper, SubscriptionMapper subscriptionMapper,
                            PaymentQrCodeMapper paymentQrCodeMapper) {
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
        this.userMapper = userMapper;
        this.userGroupMapper = userGroupMapper;
        this.deviceMapper = deviceMapper;
        this.subscriptionMapper = subscriptionMapper;
        this.paymentQrCodeMapper = paymentQrCodeMapper;
    }

    @Override
    public AdminLoginResponse login(AdminLoginRequest request) {
        if (!adminUsername.equals(request.getUsername())) {
            throw new IllegalArgumentException("用户名或密码错误");
        }
        if (!passwordEncoder.matches(request.getPassword(), adminPassword)) {
            throw new IllegalArgumentException("用户名或密码错误");
        }
        String token = jwtUtil.generateToken(0L, "admin", "admin");
        return new AdminLoginResponse(token, adminUsername);
    }

    @Override
    public String refreshToken(String token) {
        return jwtUtil.refreshToken(token);
    }

    @Override
    public StatsOverviewVO getStatsOverview() {
        long totalUsers = userMapper.selectCount(null);
        long totalDevices = deviceMapper.selectCount(null);
        long totalOrders = subscriptionMapper.selectCount(null);
        long activeSubscriptions = subscriptionMapper.selectCount(
            new LambdaQueryWrapper<Subscription>()
                .eq(Subscription::getPaymentStatus, "paid")
                .ge(Subscription::getEndDate, LocalDate.now())
        );

        // Calculate total revenue from paid subscriptions
        List<Subscription> paidSubs = subscriptionMapper.selectList(
            new LambdaQueryWrapper<Subscription>().eq(Subscription::getPaymentStatus, "paid")
        );
        BigDecimal totalRevenue = paidSubs.stream()
            .map(Subscription::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Today stats
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        long todayNewUsers = userMapper.selectCount(
            new LambdaQueryWrapper<User>().ge(User::getCreatedAt, todayStart)
        );
        long todayNewOrders = subscriptionMapper.selectCount(
            new LambdaQueryWrapper<Subscription>().ge(Subscription::getCreatedAt, todayStart)
        );

        return new StatsOverviewVO(totalUsers, totalDevices, totalOrders, activeSubscriptions,
                totalRevenue, todayNewUsers, todayNewOrders);
    }

    @Override
    public List<StatsTrendVO> getStatsTrend(int days) {
        List<StatsTrendVO> result = new ArrayList<>();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("MM-dd");

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            LocalDateTime dayStart = date.atStartOfDay();
            LocalDateTime dayEnd = date.atTime(LocalTime.MAX);
            String dateStr = date.format(fmt);

            long newUsers = userMapper.selectCount(
                new LambdaQueryWrapper<User>()
                    .ge(User::getCreatedAt, dayStart)
                    .le(User::getCreatedAt, dayEnd)
            );
            long newOrders = subscriptionMapper.selectCount(
                new LambdaQueryWrapper<Subscription>()
                    .ge(Subscription::getCreatedAt, dayStart)
                    .le(Subscription::getCreatedAt, dayEnd)
                    .eq(Subscription::getPaymentStatus, "paid")
            );

            BigDecimal revenue = BigDecimal.ZERO;
            List<Subscription> daySubs = subscriptionMapper.selectList(
                new LambdaQueryWrapper<Subscription>()
                    .ge(Subscription::getCreatedAt, dayStart)
                    .le(Subscription::getCreatedAt, dayEnd)
                    .eq(Subscription::getPaymentStatus, "paid")
            );
            for (Subscription s : daySubs) {
                revenue = revenue.add(s.getAmount());
            }

            result.add(new StatsTrendVO(dateStr, newUsers, newOrders, revenue));
        }
        return result;
    }

    @Override
    public PageResult<AdminUserVO> listUsers(PageRequest pageRequest, String phone, String name, Integer status) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (phone != null && !phone.isEmpty()) {
            wrapper.like(User::getPhone, phone);
        }
        if (name != null && !name.isEmpty()) {
            wrapper.like(User::getName, name);
        }
        if (status != null) {
            wrapper.eq(User::getStatus, status);
        }
        applySort(wrapper, pageRequest, User.class);

        IPage<User> page = userMapper.selectPage(
            new Page<>(pageRequest.getPage(), pageRequest.getSize()), wrapper
        );

        List<AdminUserVO> records = page.getRecords().stream().map(user -> {
            AdminUserVO vo = new AdminUserVO();
            vo.setId(user.getId());
            vo.setPhone(user.getPhone());
            vo.setName(user.getName());
            vo.setIdCard(user.getIdCard());
            vo.setMaskedIdCard(IdCardValidator.maskIdCard(user.getIdCard()));
            vo.setUserGroupId(user.getUserGroupId());
            vo.setStatus(user.getStatus());
            vo.setOpenid(user.getOpenid());
            vo.setCreatedAt(user.getCreatedAt());
            vo.setUpdatedAt(user.getUpdatedAt());

            // User group name
            UserGroup group = userGroupMapper.selectById(user.getUserGroupId());
            if (group != null) vo.setUserGroupName(group.getName());

            // Device count
            vo.setDeviceCount(deviceMapper.selectCount(
                new LambdaQueryWrapper<Device>().eq(Device::getUserId, user.getId())
            ));

            // Has active subscription
            vo.setHasActiveSubscription(subscriptionMapper.selectCount(
                new LambdaQueryWrapper<Subscription>()
                    .eq(Subscription::getUserId, user.getId())
                    .eq(Subscription::getPaymentStatus, "paid")
                    .ge(Subscription::getEndDate, LocalDate.now())
            ) > 0);

            return vo;
        }).collect(Collectors.toList());

        return PageResult.of(records, page.getTotal(), pageRequest.getPage(), pageRequest.getSize());
    }

    @Override
    @Transactional
    public void updateUserStatus(Long userId, Integer status) {
        User user = userMapper.selectById(userId);
        if (user == null) throw new IllegalArgumentException("用户不存在");
        user.setStatus(status);
        userMapper.updateById(user);
    }

    @Override
    @Transactional
    public void updateUserGroup(Long userId, Integer userGroupId) {
        User user = userMapper.selectById(userId);
        if (user == null) throw new IllegalArgumentException("用户不存在");
        UserGroup group = userGroupMapper.selectById(userGroupId);
        if (group == null) throw new IllegalArgumentException("用户组不存在");
        user.setUserGroupId(userGroupId);
        userMapper.updateById(user);
    }

    @Override
    public PageResult<AdminDeviceVO> listDevices(PageRequest pageRequest, Long userId, Integer status, String osType) {
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        if (userId != null) wrapper.eq(Device::getUserId, userId);
        if (status != null) wrapper.eq(Device::getStatus, status);
        if (osType != null && !osType.isEmpty()) wrapper.eq(Device::getOsType, osType);
        applySort(wrapper, pageRequest, Device.class);

        IPage<Device> page = deviceMapper.selectPage(
            new Page<>(pageRequest.getPage(), pageRequest.getSize()), wrapper
        );

        List<AdminDeviceVO> records = page.getRecords().stream().map(device -> {
            AdminDeviceVO vo = new AdminDeviceVO();
            vo.setId(device.getId());
            vo.setUserId(device.getUserId());
            vo.setImei1(device.getImei1());
            vo.setImei2(device.getImei2());
            vo.setIosDeviceId(device.getIosDeviceId());
            vo.setDeviceName(device.getDeviceName());
            vo.setDeviceModel(device.getDeviceModel());
            vo.setOsType(device.getOsType());
            vo.setOsVersion(device.getOsVersion());
            vo.setLastIp(device.getLastIp());
            vo.setLastActiveAt(device.getLastActiveAt());
            vo.setStatus(device.getStatus());
            vo.setCreatedAt(device.getCreatedAt());

            if (device.getUserId() != null) {
                User user = userMapper.selectById(device.getUserId());
                if (user != null) {
                    vo.setUserName(user.getName());
                    vo.setUserPhone(user.getPhone());
                }
            }
            return vo;
        }).collect(Collectors.toList());

        return PageResult.of(records, page.getTotal(), pageRequest.getPage(), pageRequest.getSize());
    }

    @Override
    @Transactional
    public void updateDeviceStatus(Long deviceId, Integer status) {
        Device device = deviceMapper.selectById(deviceId);
        if (device == null) throw new IllegalArgumentException("设备不存在");
        device.setStatus(status);
        deviceMapper.updateById(device);
    }

    @Override
    public PageResult<AdminSubscriptionVO> listSubscriptions(PageRequest pageRequest, Long userId, String paymentStatus) {
        LambdaQueryWrapper<Subscription> wrapper = new LambdaQueryWrapper<>();
        if (userId != null) wrapper.eq(Subscription::getUserId, userId);
        if (paymentStatus != null && !paymentStatus.isEmpty()) wrapper.eq(Subscription::getPaymentStatus, paymentStatus);
        applySort(wrapper, pageRequest, Subscription.class);

        IPage<Subscription> page = subscriptionMapper.selectPage(
            new Page<>(pageRequest.getPage(), pageRequest.getSize()), wrapper
        );

        List<AdminSubscriptionVO> records = page.getRecords().stream().map(sub -> {
            AdminSubscriptionVO vo = new AdminSubscriptionVO();
            vo.setId(sub.getId());
            vo.setUserId(sub.getUserId());
            vo.setDeviceId(sub.getDeviceId());
            vo.setOrderNo(sub.getOrderNo());
            vo.setStartDate(sub.getStartDate());
            vo.setEndDate(sub.getEndDate());
            vo.setAmount(sub.getAmount());
            vo.setDiscountAmount(sub.getDiscountAmount());
            vo.setPaymentMethod(sub.getPaymentMethod());
            vo.setPaymentStatus(sub.getPaymentStatus());
            vo.setCreatedAt(sub.getCreatedAt());
            vo.setDaysRemaining(java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(), sub.getEndDate()));

            if (sub.getUserId() != null) {
                User user = userMapper.selectById(sub.getUserId());
                if (user != null) {
                    vo.setUserName(user.getName());
                    vo.setUserPhone(user.getPhone());
                }
            }
            if (sub.getDeviceId() != null) {
                Device device = deviceMapper.selectById(sub.getDeviceId());
                if (device != null) vo.setDeviceName(device.getDeviceName());
            }
            return vo;
        }).collect(Collectors.toList());

        return PageResult.of(records, page.getTotal(), pageRequest.getPage(), pageRequest.getSize());
    }

    @Override
    public PageResult<AdminOrderVO> listOrders(PageRequest pageRequest, Long userId, String status) {
        // Query payment_qr_codes as orders
        LambdaQueryWrapper<PaymentQrCode> wrapper = new LambdaQueryWrapper<>();
        if (userId != null) wrapper.eq(PaymentQrCode::getUserId, userId);
        if (status != null && !status.isEmpty()) wrapper.eq(PaymentQrCode::getStatus, status);
        applySort(wrapper, pageRequest, PaymentQrCode.class);

        IPage<PaymentQrCode> page = paymentQrCodeMapper.selectPage(
            new Page<>(pageRequest.getPage(), pageRequest.getSize()), wrapper
        );

        List<AdminOrderVO> records = page.getRecords().stream().map(qr -> {
            AdminOrderVO vo = new AdminOrderVO();
            vo.setId(qr.getId());
            vo.setOrderNo(qr.getOrderNo());
            vo.setType("payment_qr_code");
            vo.setUserId(qr.getUserId());
            vo.setDeviceId(qr.getDeviceId());
            vo.setAmount(qr.getAmount());
            vo.setStatus(qr.getStatus());
            vo.setExpiredAt(qr.getExpiredAt());
            vo.setPaidAt(qr.getPaidAt());
            vo.setCreatedAt(qr.getCreatedAt());

            if (qr.getUserId() != null) {
                User user = userMapper.selectById(qr.getUserId());
                if (user != null) {
                    vo.setUserName(user.getName());
                    vo.setUserPhone(user.getPhone());
                }
            }
            if (qr.getDeviceId() != null) {
                Device device = deviceMapper.selectById(qr.getDeviceId());
                if (device != null) vo.setDeviceName(device.getDeviceName());
            }
            return vo;
        }).collect(Collectors.toList());

        return PageResult.of(records, page.getTotal(), pageRequest.getPage(), pageRequest.getSize());
    }

    @Override
    @Transactional
    public void refundOrder(String orderNo) {
        // Update subscription
        Subscription sub = subscriptionMapper.selectOne(
            new LambdaQueryWrapper<Subscription>().eq(Subscription::getOrderNo, orderNo)
        );
        if (sub == null) throw new IllegalArgumentException("订单不存在");
        if (!"paid".equals(sub.getPaymentStatus())) throw new IllegalArgumentException("只能退款已支付的订单");

        sub.setPaymentStatus("refunded");
        subscriptionMapper.updateById(sub);

        // Update payment QR code if exists
        PaymentQrCode qr = paymentQrCodeMapper.selectOne(
            new LambdaQueryWrapper<PaymentQrCode>().eq(PaymentQrCode::getOrderNo, orderNo)
        );
        if (qr != null) {
            qr.setStatus("expired");
            paymentQrCodeMapper.updateById(qr);
        }
    }

    private <T> void applySort(LambdaQueryWrapper<T> wrapper, PageRequest pageRequest, Class<T> entityClass) {
        // Default: order by id desc
        wrapper.last("ORDER BY id DESC");
    }
}
