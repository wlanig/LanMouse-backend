package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import java.time.LocalDateTime;

@TableName("devices")
public class Device {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String imei1;
    private String imei2;
    private String iosDeviceId;
    private String deviceName;
    private String deviceModel;
    private String osType;
    private String osVersion;
    private String lastIp;
    private LocalDateTime lastActiveAt;
    private String bindToken;
    private LocalDateTime bindTokenExpire;
    private Integer status;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    // Getter and Setter
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getImei1() { return imei1; }
    public void setImei1(String imei1) { this.imei1 = imei1; }
    public String getImei2() { return imei2; }
    public void setImei2(String imei2) { this.imei2 = imei2; }
    public String getIosDeviceId() { return iosDeviceId; }
    public void setIosDeviceId(String iosDeviceId) { this.iosDeviceId = iosDeviceId; }
    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }
    public String getDeviceModel() { return deviceModel; }
    public void setDeviceModel(String deviceModel) { this.deviceModel = deviceModel; }
    public String getOsType() { return osType; }
    public void setOsType(String osType) { this.osType = osType; }
    public String getOsVersion() { return osVersion; }
    public void setOsVersion(String osVersion) { this.osVersion = osVersion; }
    public String getLastIp() { return lastIp; }
    public void setLastIp(String lastIp) { this.lastIp = lastIp; }
    public LocalDateTime getLastActiveAt() { return lastActiveAt; }
    public void setLastActiveAt(LocalDateTime lastActiveAt) { this.lastActiveAt = lastActiveAt; }
    public String getBindToken() { return bindToken; }
    public void setBindToken(String bindToken) { this.bindToken = bindToken; }
    public LocalDateTime getBindTokenExpire() { return bindTokenExpire; }
    public void setBindTokenExpire(LocalDateTime bindTokenExpire) { this.bindTokenExpire = bindTokenExpire; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
