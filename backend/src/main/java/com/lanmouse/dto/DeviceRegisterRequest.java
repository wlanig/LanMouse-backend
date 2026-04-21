package com.lanmouse.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;

@Data
public class DeviceRegisterRequest {

    private String imei1;

    private String imei2;

    private String iosDeviceId;

    @NotBlank(message = "设备名称不能为空")
    private String deviceName;

    private String deviceModel;

    @NotBlank(message = "操作系统类型不能为空")
    private String osType;

    private String osVersion;
}
