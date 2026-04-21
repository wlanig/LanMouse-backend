package com.lanmouse.dto;

public class DeviceRegisterResponse {
    private Long deviceId;
    private String deviceToken;

    public DeviceRegisterResponse() {}
    
    public DeviceRegisterResponse(Long deviceId, String deviceToken) {
        this.deviceId = deviceId;
        this.deviceToken = deviceToken;
    }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getDeviceToken() { return deviceToken; }
    public void setDeviceToken(String deviceToken) { this.deviceToken = deviceToken; }
}
