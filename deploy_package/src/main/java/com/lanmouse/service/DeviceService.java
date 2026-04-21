package com.lanmouse.service;

import com.lanmouse.entity.Device;
import com.lanmouse.controller.DeviceController.RegisterDeviceRequest;
import com.lanmouse.controller.DeviceController.UpdateDeviceRequest;

import java.util.List;
import java.util.Map;

/**
 * 设备服务接口
 */
public interface DeviceService {
    Device register(Long userId, RegisterDeviceRequest request, String bindToken);
    boolean bindDevice(Long userId, String bindToken);
    boolean unbindDevice(Long userId, Long deviceId);
    boolean updateDevice(Long userId, Long deviceId, UpdateDeviceRequest request);
    Device findById(Long id);
    Device findByImei(String imei);
    Device findByIosDeviceId(String iosDeviceId);
    List<Map<String, Object>> getDeviceList(Long userId);
    Map<String, Object> getDeviceDetail(Device device);
    Map<String, Object> getSubscriptionInfo(Long deviceId);
    void updateHeartbeat(Long deviceId, String ip);
    Map<String, Object> verifySubscription(Long deviceId, String imei);
    Map<String, Object> batchVerify(List<Map<String, Object>> devices);
}
