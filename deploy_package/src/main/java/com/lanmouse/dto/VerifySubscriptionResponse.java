package com.lanmouse.dto;

public class VerifySubscriptionResponse {
    private boolean valid;
    private Long userId;
    private Long deviceId;
    private String message;

    public VerifySubscriptionResponse() {}
    
    public VerifySubscriptionResponse(boolean valid, Long userId, Long deviceId, String message) {
        this.valid = valid;
        this.userId = userId;
        this.deviceId = deviceId;
        this.message = message;
    }

    public boolean isValid() { return valid; }
    public void setValid(boolean valid) { this.valid = valid; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
