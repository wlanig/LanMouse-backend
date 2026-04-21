package com.lanmouse.dto;

import javax.validation.constraints.NotBlank;

/**
 * 微信登录请求
 */
public class WechatLoginRequest {

    @NotBlank(message = "code不能为空")
    private String code;

    private String nickname;

    private String avatarUrl;

    private String phone;

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
}
