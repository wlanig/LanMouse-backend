package com.lanmouse.dto;

import java.time.LocalDateTime;

public class DeviceListResponse {
    private Long deviceId;
    private String deviceName;
    private String osType;
    private Integer status;
    private LocalDateTime lastActiveAt;
    private boolean subscribed;

    public DeviceListResponse() {}

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }
    public String getOsType() { return osType; }
    public void setOsType(String osType) { this.osType = osType; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getLastActiveAt() { return lastActiveAt; }
    public void setLastActiveAt(LocalDateTime lastActiveAt) { this.lastActiveAt = lastActiveAt; }
    public boolean isSubscribed() { return subscribed; }
    public void setSubscribed(boolean subscribed) { this.subscribed = subscribed; }
}
