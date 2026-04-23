package com.lanmouse.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AdminDeviceVO {
    private Long id;
    private Long userId;
    private String userName;
    private String userPhone;
    private String imei1;
    private String imei2;
    private String iosDeviceId;
    private String deviceName;
    private String deviceModel;
    private String osType;
    private String osVersion;
    private String lastIp;
    private LocalDateTime lastActiveAt;
    private Integer status;
    private LocalDateTime createdAt;
}
