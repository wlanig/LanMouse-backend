package com.lanmouse.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class AdminUserVO {
    private Long id;
    private String phone;
    private String name;
    private String idCard;
    private String maskedIdCard;
    private Integer userGroupId;
    private String userGroupName;
    private Integer status;
    private String openid;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private long deviceCount;
    private boolean hasActiveSubscription;
}
