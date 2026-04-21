package com.lanmouse.dto;

public class LoginResponse {
    private String token;
    private String refreshToken;
    private Long userId;
    private String phone;
    private String name;
    private String maskedIdCard;
    private UserGroupInfo userGroup;

    public LoginResponse() {}

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getMaskedIdCard() { return maskedIdCard; }
    public void setMaskedIdCard(String maskedIdCard) { this.maskedIdCard = maskedIdCard; }
    public UserGroupInfo getUserGroup() { return userGroup; }
    public void setUserGroup(UserGroupInfo userGroup) { this.userGroup = userGroup; }

    public static class UserGroupInfo {
        private Integer id;
        private String name;
        private String annualFee;

        public Integer getId() { return id; }
        public void setId(Integer id) { this.id = id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getAnnualFee() { return annualFee; }
        public void setAnnualFee(String annualFee) { this.annualFee = annualFee; }
    }
}
