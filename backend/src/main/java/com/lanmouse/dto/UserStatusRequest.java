package com.lanmouse.dto;

import lombok.Data;

@Data
public class UserStatusRequest {
    private Integer status; // 0=禁用, 1=正常
}
