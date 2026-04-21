package com.lanmouse.controller;

import com.lanmouse.config.JwtInterceptor;
import com.lanmouse.dto.*;
import com.lanmouse.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

@RestController
@RequestMapping("/api/subscription")
public class SubscriptionController {

    @Autowired
    private SubscriptionService subscriptionService;

    /**
     * 创建订阅订单
     * POST /api/subscription/create-order
     */
    @PostMapping("/create-order")
    public ApiResponse<CreateOrderResponse> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute(JwtInterceptor.USER_ID_KEY);
        CreateOrderResponse response = subscriptionService.createOrder(request, userId);
        return ApiResponse.success(response);
    }

    /**
     * 获取订阅状态
     * GET /api/subscription/status/{deviceId}
     */
    @GetMapping("/status/{deviceId}")
    public ApiResponse<SubscriptionStatusResponse> getStatus(
            @PathVariable Long deviceId,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute(JwtInterceptor.USER_ID_KEY);
        SubscriptionStatusResponse response = subscriptionService.getStatus(deviceId, userId);
        return ApiResponse.success(response);
    }
}
