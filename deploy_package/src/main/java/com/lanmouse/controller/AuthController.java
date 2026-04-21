package com.lanmouse.controller;

import com.lanmouse.dto.*;
import com.lanmouse.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * 用户注册
     * POST /api/auth/register
     */
    @PostMapping("/register")
    public ApiResponse<LoginResponse> register(@Valid @RequestBody RegisterRequest request) {
        LoginResponse response = authService.register(request);
        return ApiResponse.success(response);
    }

    /**
     * 用户登录
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ApiResponse.success(response);
    }

    /**
     * 刷新Token
     * POST /api/auth/refresh
     */
    @PostMapping("/refresh")
    public ApiResponse<String> refresh(@RequestHeader("Authorization") String refreshToken) {
        String token = authService.refreshToken(refreshToken.replace("Bearer ", ""));
        return ApiResponse.success(token);
    }
}
