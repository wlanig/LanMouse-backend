package com.lanmouse.service;

import com.lanmouse.dto.*;

/**
 * 订阅服务接口
 */
public interface SubscriptionService {
    CreateOrderResponse createOrder(CreateOrderRequest request, Long userId);
    SubscriptionStatusResponse getStatus(Long deviceId, Long userId);
    VerifySubscriptionResponse verifySubscription(Long deviceId, String imei);
    void handlePaymentCallback(String orderNo);
}
