package com.lanmouse.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lanmouse.dto.*;
import com.lanmouse.entity.Device;
import com.lanmouse.entity.Subscription;
import com.lanmouse.mapper.DeviceMapper;
import com.lanmouse.mapper.SubscriptionMapper;
import com.lanmouse.service.DeviceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class DeviceServiceImpl implements DeviceService {

    @Autowired
    private DeviceMapper deviceMapper;

    @Autowired
    private SubscriptionMapper subscriptionMapper;

    private static final int PC_SERVICE_PORT = 19876;

    @Override
    @Transactional
    public DeviceRegisterResponse register(DeviceRegisterRequest request, Long userId) {
        // 检查设备是否已存在
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        if (request.getImei1() != null && !request.getImei1().isEmpty()) {
            wrapper.eq(Device::getImei1, request.getImei1()).or();
        }
        if (request.getImei2() != null && !request.getImei2().isEmpty()) {
            wrapper.eq(Device::getImei2, request.getImei2()).or();
        }
        if (request.getIosDeviceId() != null && !request.getIosDeviceId().isEmpty()) {
            wrapper.eq(Device::getIosDeviceId, request.getIosDeviceId());
        }

        Device existingDevice = deviceMapper.selectOne(wrapper);
        if (existingDevice != null) {
            // 设备已存在，更新用户绑定
            existingDevice.setUserId(userId);
            existingDevice.setStatus(0); // 未激活状态
            existingDevice.setBindToken(UUID.randomUUID().toString().replace("-", ""));
            deviceMapper.updateById(existingDevice);

            DeviceRegisterResponse response = new DeviceRegisterResponse();
            response.setDeviceId(existingDevice.getId());
            response.setBindToken(existingDevice.getBindToken());
            response.setPcServicePort(PC_SERVICE_PORT);
            return response;
        }

        // 创建新设备
        Device device = new Device();
        device.setUserId(userId);
        device.setImei1(request.getImei1());
        device.setImei2(request.getImei2());
        device.setIosDeviceId(request.getIosDeviceId());
        device.setDeviceName(request.getDeviceName());
        device.setDeviceModel(request.getDeviceModel());
        device.setOsType(request.getOsType());
        device.setOsVersion(request.getOsVersion());
        device.setStatus(0); // 未激活状态
        device.setBindToken(UUID.randomUUID().toString().replace("-", ""));

        deviceMapper.insert(device);

        DeviceRegisterResponse response = new DeviceRegisterResponse();
        response.setDeviceId(device.getId());
        response.setBindToken(device.getBindToken());
        response.setPcServicePort(PC_SERVICE_PORT);

        return response;
    }

    @Override
    @Transactional
    public void bind(BindRequest request) {
        // 查找绑定令牌对应的设备
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Device::getBindToken, request.getBindToken());
        Device device = deviceMapper.selectOne(wrapper);

        if (device == null) {
            throw new IllegalArgumentException("绑定令牌无效");
        }

        if (device.getStatus() == 1) {
            throw new IllegalArgumentException("设备已绑定，无需重复绑定");
        }

        // 激活设备
        device.setStatus(1);
        device.setBindToken(null); // 清除绑定令牌
        deviceMapper.updateById(device);
    }

    @Override
    public List<DeviceListResponse> list(Long userId) {
        LambdaQueryWrapper<Device> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(Device::getUserId, userId);
        wrapper.orderByDesc(Device::getCreatedAt);
        List<Device> devices = deviceMapper.selectList(wrapper);

        List<DeviceListResponse> responses = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        for (Device device : devices) {
            DeviceListResponse response = new DeviceListResponse();
            response.setDeviceId(device.getId());
            response.setDeviceName(device.getDeviceName());
            response.setDeviceModel(device.getDeviceModel());
            response.setStatus(device.getStatus());
            response.setLastActiveAt(device.getLastActiveAt() != null ? 
                    device.getLastActiveAt().format(formatter) : null);

            // 查询订阅状态
            LambdaQueryWrapper<Subscription> subWrapper = new LambdaQueryWrapper<>();
            subWrapper.eq(Subscription::getDeviceId, device.getId());
            subWrapper.eq(Subscription::getPaymentStatus, "PAID");
            subWrapper.ge(Subscription::getEndDate, LocalDate.now());
            subWrapper.orderByDesc(Subscription::getEndDate);
            Subscription subscription = subscriptionMapper.selectOne(subWrapper);

            if (subscription != null) {
                DeviceListResponse.SubscriptionInfo subscriptionInfo = 
                        new DeviceListResponse.SubscriptionInfo();
                subscriptionInfo.setEndDate(subscription.getEndDate().toString());
                subscriptionInfo.setStatus("active");
                response.setSubscription(subscriptionInfo);
            }

            responses.add(response);
        }

        return responses;
    }

    @Override
    public DeviceListResponse getById(Long deviceId) {
        Device device = deviceMapper.selectById(deviceId);
        if (device == null) {
            throw new IllegalArgumentException("设备不存在");
        }

        DeviceListResponse response = new DeviceListResponse();
        response.setDeviceId(device.getId());
        response.setDeviceName(device.getDeviceName());
        response.setDeviceModel(device.getDeviceModel());
        response.setStatus(device.getStatus());
        response.setLastActiveAt(device.getLastActiveAt() != null ? 
                device.getLastActiveAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")) : null);

        return response;
    }
}
