package com.lanmouse.controller;

import com.lanmouse.config.JwtInterceptor;
import com.lanmouse.dto.*;
import com.lanmouse.service.DeviceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/device")
public class DeviceController {

    @Autowired
    private DeviceService deviceService;

    /**
     * 设备注册
     * POST /api/device/register
     */
    @PostMapping("/register")
    public ApiResponse<DeviceRegisterResponse> register(
            @Valid @RequestBody DeviceRegisterRequest request,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute(JwtInterceptor.USER_ID_KEY);
        DeviceRegisterResponse response = deviceService.register(request, userId);
        return ApiResponse.success(response);
    }

    /**
     * 设备绑定（PC端）
     * POST /api/device/bind
     */
    @PostMapping("/bind")
    public ApiResponse<Void> bind(@Valid @RequestBody BindRequest request) {
        deviceService.bind(request);
        return ApiResponse.successMsg("绑定成功");
    }

    /**
     * 获取设备列表
     * GET /api/device/list
     */
    @GetMapping("/list")
    public ApiResponse<List<DeviceListResponse>> list(HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute(JwtInterceptor.USER_ID_KEY);
        List<DeviceListResponse> devices = deviceService.list(userId);
        return ApiResponse.success(devices);
    }

    /**
     * 获取设备详情
     * GET /api/device/{deviceId}
     */
    @GetMapping("/{deviceId}")
    public ApiResponse<DeviceListResponse> getById(@PathVariable Long deviceId) {
        DeviceListResponse device = deviceService.getById(deviceId);
        return ApiResponse.success(device);
    }
}
