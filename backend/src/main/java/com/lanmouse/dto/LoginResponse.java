package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private Long userId;
    private String token;
    private String maskedIdCard;
    private String name;
    private Boolean newUser;
    private UserGroupInfo userGroup;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserGroupInfo {
        private Integer id;
        private String name;
        private String annualFee;
    }
}
