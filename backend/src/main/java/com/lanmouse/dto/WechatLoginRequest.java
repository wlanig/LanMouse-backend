package com.lanmouse.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;

/**
 * 微信登录请求
 */
@Data
public class WechatLoginRequest {
    
    /**
     * 微信小程序调用wx.login()获取的code
     */
    @NotBlank(message = "code不能为空")
    private String code;
    
    /**
     * 用户昵称（可选）
     */
    private String nickname;
    
    /**
     * 用户头像URL（可选）
     */
    private String avatarUrl;

    /**
     * 用户手机号（可选，用于绑定手机号）
     */
    private String phone;
}
