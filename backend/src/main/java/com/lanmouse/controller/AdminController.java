package com.lanmouse.controller;

import com.lanmouse.dto.*;
import com.lanmouse.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private AdminService adminService;

    // ── 认证 ──

    @PostMapping("/login")
    public ApiResponse<AdminLoginResponse> login(@RequestBody AdminLoginRequest request) {
        return ApiResponse.success(adminService.login(request));
    }

    @PostMapping("/refresh")
    public ApiResponse<String> refreshToken(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.substring(7);
        String newToken = adminService.refreshToken(token);
        if (newToken == null) {
            return ApiResponse.error("刷新Token失败");
        }
        return ApiResponse.success(newToken);
    }

    // ── 数据统计 ──

    @GetMapping("/stats/overview")
    public ApiResponse<StatsOverviewVO> getStatsOverview() {
        return ApiResponse.success(adminService.getStatsOverview());
    }

    @GetMapping("/stats/trend")
    public ApiResponse<List<StatsTrendVO>> getStatsTrend(
            @RequestParam(defaultValue = "30") int days) {
        return ApiResponse.success(adminService.getStatsTrend(days));
    }

    // ── 用户管理 ──

    @GetMapping("/users")
    public ApiResponse<PageResult<AdminUserVO>> listUsers(
            PageRequest pageRequest,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Integer status) {
        return ApiResponse.success(adminService.listUsers(pageRequest, phone, name, status));
    }

    @PutMapping("/users/{id}/status")
    public ApiResponse<Void> updateUserStatus(
            @PathVariable Long id,
            @RequestBody UserStatusRequest request) {
        adminService.updateUserStatus(id, request.getStatus());
        return ApiResponse.successMsg("用户状态已更新");
    }

    @PutMapping("/users/{id}/group")
    public ApiResponse<Void> updateUserGroup(
            @PathVariable Long id,
            @RequestBody UserGroupRequest request) {
        adminService.updateUserGroup(id, request.getUserGroupId());
        return ApiResponse.successMsg("用户组已更新");
    }

    // ── 设备管理 ──

    @GetMapping("/devices")
    public ApiResponse<PageResult<AdminDeviceVO>> listDevices(
            PageRequest pageRequest,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String osType) {
        return ApiResponse.success(adminService.listDevices(pageRequest, userId, status, osType));
    }

    @PutMapping("/devices/{id}/status")
    public ApiResponse<Void> updateDeviceStatus(
            @PathVariable Long id,
            @RequestBody DeviceStatusRequest request) {
        adminService.updateDeviceStatus(id, request.getStatus());
        return ApiResponse.successMsg("设备状态已更新");
    }

    // ── 订阅管理 ──

    @GetMapping("/subscriptions")
    public ApiResponse<PageResult<AdminSubscriptionVO>> listSubscriptions(
            PageRequest pageRequest,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String paymentStatus) {
        return ApiResponse.success(adminService.listSubscriptions(pageRequest, userId, paymentStatus));
    }

    // ── 订单管理 ──

    @GetMapping("/orders")
    public ApiResponse<PageResult<AdminOrderVO>> listOrders(
            PageRequest pageRequest,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String status) {
        return ApiResponse.success(adminService.listOrders(pageRequest, userId, status));
    }

    @PutMapping("/orders/{orderNo}/refund")
    public ApiResponse<Void> refundOrder(@PathVariable String orderNo) {
        adminService.refundOrder(orderNo);
        return ApiResponse.successMsg("订单已退款");
    }
}
