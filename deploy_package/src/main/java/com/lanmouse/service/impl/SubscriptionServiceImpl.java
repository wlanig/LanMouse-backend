package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.dto.*;
import com.lanmouse.entity.*;
import com.lanmouse.mapper.*;
import com.lanmouse.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Service
public class SubscriptionServiceImpl implements SubscriptionService {

    @Autowired
    private SubscriptionMapper subscriptionMapper;

    @Autowired
    private PaymentQrCodeMapper paymentQrCodeMapper;

    @Autowired
    private DeviceMapper deviceMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private UserGroupMapper userGroupMapper;

    @Value("${payment.qr-code-expiration-minutes:30}")
    private Integer qrCodeExpirationMinutes;

    @Value("${payment.qr-code-base-url:https://api.lanmouse.com/payment/qr/}")
    private String qrCodeBaseUrl;

    @Override
    @Transactional
    public CreateOrderResponse createOrder(CreateOrderRequest request, Long userId) {
        // 验证设备归属
        Device device = deviceMapper.selectById(request.getDeviceId());
        if (device == null) {
            throw new IllegalArgumentException("设备不存在");
        }
        if (!device.getUserId().equals(userId)) {
            throw new IllegalArgumentException("设备不属于当前用户");
        }

        // 获取用户组定价
        User user = userMapper.selectById(userId);
        UserGroup userGroup = userGroupMapper.selectById(user.getUserGroupId());

        BigDecimal annualFee = userGroup.getAnnualFee();
        BigDecimal discountAmount = annualFee.multiply(userGroup.getDiscountRate().subtract(BigDecimal.ONE)).abs();
        BigDecimal actualAmount = annualFee.subtract(discountAmount);

        // 生成订单号
        String orderNo = "SUB" + System.currentTimeMillis();

        // 创建支付二维码记录
        PaymentQrCode qrCode = new PaymentQrCode();
        qrCode.setQrCode(UUID.randomUUID().toString().replace("-", ""));
        qrCode.setOrderNo(orderNo);
        qrCode.setAmount(actualAmount);
        qrCode.setUserId(userId);
        qrCode.setDeviceId(request.getDeviceId());
        qrCode.setStatus("pending");
        qrCode.setExpiredAt(LocalDateTime.now().plusMinutes(qrCodeExpirationMinutes));

        paymentQrCodeMapper.insert(qrCode);

        // 构建响应
        CreateOrderResponse response = new CreateOrderResponse();
        response.setOrderNo(orderNo);
        response.setAmount(actualAmount.toString());
        response.setDiscountAmount(discountAmount.toString());
        response.setQrCodeUrl(qrCodeBaseUrl + qrCode.getQrCode());
        response.setExpireMinutes(qrCodeExpirationMinutes);

        return response;
    }

    @Override
    public SubscriptionStatusResponse getStatus(Long deviceId, Long userId) {
        // 验证设备归属
        Device device = deviceMapper.selectById(deviceId);
        if (device == null) {
            throw new IllegalArgumentException("设备不存在");
        }
        if (!device.getUserId().equals(userId)) {
            throw new IllegalArgumentException("设备不属于当前用户");
        }

        SubscriptionStatusResponse response = new SubscriptionStatusResponse();

        // 查询有效订阅
        LambdaQueryWrapper<Subscription> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Subscription::getDeviceId, deviceId);
        wrapper.eq(Subscription::getPaymentStatus, "PAID");
        wrapper.ge(Subscription::getEndDate, LocalDate.now());
        wrapper.orderByDesc(Subscription::getEndDate);
        Subscription subscription = subscriptionMapper.selectOne(wrapper);

        if (subscription != null) {
            response.setSubscribed(true);
            response.setEndDate(subscription.getEndDate().toString());
            response.setDaysRemaining((int) ChronoUnit.DAYS.between(LocalDate.now(), subscription.getEndDate()));
            response.setAutoRenew(false);
        } else {
            response.setSubscribed(false);
            response.setEndDate(null);
            response.setDaysRemaining(0);
            response.setAutoRenew(false);
        }

        return response;
    }

    @Override
    public VerifySubscriptionResponse verifySubscription(Long deviceId, String imei) {
        // 验证设备
        Device device = deviceMapper.selectById(deviceId);
        if (device == null) {
            throw new IllegalArgumentException("设备不存在");
        }

        // 验证IMEI
        if (device.getImei1() != null && !device.getImei1().equals(imei) &&
            device.getImei2() != null && !device.getImei2().equals(imei)) {
            throw new IllegalArgumentException("IMEI不匹配");
        }

        VerifySubscriptionResponse response = new VerifySubscriptionResponse();

        // 查询有效订阅
        LambdaQueryWrapper<Subscription> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Subscription::getDeviceId, deviceId);
        wrapper.eq(Subscription::getPaymentStatus, "PAID");
        wrapper.ge(Subscription::getEndDate, LocalDate.now());
        wrapper.orderByDesc(Subscription::getEndDate);
        Subscription subscription = subscriptionMapper.selectOne(wrapper);

        if (subscription != null) {
            response.setValid(true);
            response.setEndDate(subscription.getEndDate().toString());
            response.setDaysRemaining((int) ChronoUnit.DAYS.between(LocalDate.now(), subscription.getEndDate()));
        } else {
            response.setValid(false);
            response.setEndDate(null);
            response.setDaysRemaining(0);
        }

        return response;
    }

    /**
     * 支付回调处理
     */
    @Transactional
    public void handlePaymentCallback(String orderNo) {
        // 查询支付二维码
        LambdaQueryWrapper<PaymentQrCode> qrWrapper = new LambdaQueryWrapper<>();
        qrWrapper.eq(PaymentQrCode::getOrderNo, orderNo);
        qrWrapper.eq(PaymentQrCode::getStatus, "pending");
        PaymentQrCode qrCode = paymentQrCodeMapper.selectOne(qrWrapper);

        if (qrCode == null) {
            return;
        }

        if (qrCode.getExpiredAt().isBefore(LocalDateTime.now())) {
            qrCode.setStatus("expired");
            paymentQrCodeMapper.updateById(qrCode);
            return;
        }

        // 更新二维码状态
        qrCode.setStatus("paid");
        qrCode.setPaidAt(LocalDateTime.now());
        paymentQrCodeMapper.updateById(qrCode);

        // 创建或更新订阅
        LocalDate startDate = LocalDate.now();
        LocalDate endDate = startDate.plusYears(1);

        LambdaQueryWrapper<Subscription> subWrapper = new LambdaQueryWrapper<>();
        subWrapper.eq(Subscription::getDeviceId, qrCode.getDeviceId());
        subWrapper.eq(Subscription::getPaymentStatus, "PAID");
        Subscription existingSub = subscriptionMapper.selectOne(subWrapper);

        if (existingSub != null && existingSub.getEndDate().isAfter(startDate)) {
            // 续费：在现有有效期基础上增加一年
            endDate = existingSub.getEndDate().plusYears(1);
            existingSub.setEndDate(endDate);
            existingSub.setAmount(qrCode.getAmount());
            existingSub.setUpdatedAt(LocalDateTime.now());
            subscriptionMapper.updateById(existingSub);
        } else {
            // 新订阅
            Subscription subscription = new Subscription();
            subscription.setUserId(qrCode.getUserId());
            subscription.setDeviceId(qrCode.getDeviceId());
            subscription.setOrderNo(orderNo);
            subscription.setStartDate(startDate);
            subscription.setEndDate(endDate);
            subscription.setAmount(qrCode.getAmount());
            subscription.setPaymentStatus("PAID");
            subscription.setPaymentMethod("QR_CODE");
            subscriptionMapper.insert(subscription);
        }
    }
}
