package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceRegisterResponse {

    private Long deviceId;
    private String bindToken;
    private Integer pcServicePort;
}
