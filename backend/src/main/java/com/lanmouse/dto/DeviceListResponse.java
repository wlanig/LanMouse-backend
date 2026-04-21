package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceListResponse {

    private Long deviceId;
    private String deviceName;
    private String deviceModel;
    private Integer status;
    private String lastActiveAt;
    private SubscriptionInfo subscription;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubscriptionInfo {
        private String endDate;
        private String status;
    }
}
