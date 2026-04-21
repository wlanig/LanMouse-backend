package com.lanmouse.service;

import java.util.Map;

/**
 * 订阅服务接口
 */
public interface SubscriptionService {
    Map<String, Object> createOrder(Long userId, Long deviceId);
    Map<String, Object> getSubscriptionStatus(Long userId, Long deviceId);
    void handlePaymentCallback(String orderNo, String status);
    Map<String, Object> getOrderDetail(String orderNo);
    Map<String, Object> getUserOrders(Long userId, int page, int size);
    boolean cancelOrder(Long userId, String orderNo);
}
