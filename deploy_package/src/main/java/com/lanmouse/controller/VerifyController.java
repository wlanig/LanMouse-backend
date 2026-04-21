package com.lanmouse.controller;

import com.lanmouse.dto.*;
import com.lanmouse.service.SubscriptionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/verify")
public class VerifyController {

    @Autowired
    private SubscriptionService subscriptionService;

    /**
     * PC端验证订阅
     * GET /api/verify/subscription?deviceId=xxx&imei=xxx
     */
    @GetMapping("/subscription")
    public ApiResponse<VerifySubscriptionResponse> verifySubscription(
            @RequestParam Long deviceId,
            @RequestParam String imei) {
        VerifySubscriptionResponse response = subscriptionService.verifySubscription(deviceId, imei);
        return ApiResponse.success(response);
    }
}
