package com.lanmouse.service;

import com.lanmouse.dto.*;

import java.util.List;

/**
 * 设备服务接口
 */
public interface DeviceService {
    DeviceRegisterResponse register(DeviceRegisterRequest request, Long userId);
    void bind(BindRequest request);
    List<DeviceListResponse> list(Long userId);
    DeviceListResponse getById(Long deviceId);
}
