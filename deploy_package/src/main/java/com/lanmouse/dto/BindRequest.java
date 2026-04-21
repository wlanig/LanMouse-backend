package com.lanmouse.dto;

public class BindRequest {
    private Long deviceId;
    private String bindToken;

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getBindToken() { return bindToken; }
    public void setBindToken(String bindToken) { this.bindToken = bindToken; }
}
