package com.lanmouse.service;

import com.lanmouse.dto.*;

public interface AuthService {

    /**
     * 用户注册
     */
    LoginResponse register(RegisterRequest request);

    /**
     * 用户登录
     */
    LoginResponse login(LoginRequest request);

    /**
     * 刷新Token
     */
    String refreshToken(String refreshToken);
}
