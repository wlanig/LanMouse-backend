package com.lanmouse.dto;

public class DeviceRegisterRequest {
    private String imei1;
    private String imei2;
    private String iosDeviceId;
    private String deviceName;
    private String deviceModel;
    private String osType;
    private String osVersion;

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
}
