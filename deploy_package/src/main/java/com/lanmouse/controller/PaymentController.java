package com.lanmouse.controller;

import com.lanmouse.dto.ApiResponse;
import com.lanmouse.service.impl.SubscriptionServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {

    @Autowired
    private SubscriptionServiceImpl subscriptionService;

    /**
     * 支付回调
     * GET /api/payment/callback?orderNo=xxx
     */
    @GetMapping("/callback")
    public ApiResponse<Void> callback(@RequestParam String orderNo) {
        subscriptionService.handlePaymentCallback(orderNo);
        return ApiResponse.success("回调处理成功");
    }

    /**
     * 支付回调（POST格式）
     * POST /api/payment/callback
     */
    @PostMapping("/callback")
    public ApiResponse<Void> callbackPost(@RequestParam String orderNo) {
        subscriptionService.handlePaymentCallback(orderNo);
        return ApiResponse.success("回调处理成功");
    }
}
