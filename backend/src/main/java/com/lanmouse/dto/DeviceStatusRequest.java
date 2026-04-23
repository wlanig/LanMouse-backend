package com.lanmouse.dto;

import lombok.Data;

@Data
public class DeviceStatusRequest {
    private Integer status; // 0=未激活, 1=正常, 2=冻结
}
