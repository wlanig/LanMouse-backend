package com.lanmouse.service;

import com.lanmouse.dto.*;

import java.util.List;

public interface AdminService {

    AdminLoginResponse login(AdminLoginRequest request);

    String refreshToken(String token);

    StatsOverviewVO getStatsOverview();

    List<StatsTrendVO> getStatsTrend(int days);

    PageResult<AdminUserVO> listUsers(PageRequest pageRequest, String phone, String name, Integer status);

    void updateUserStatus(Long userId, Integer status);

    void updateUserGroup(Long userId, Integer userGroupId);

    PageResult<AdminDeviceVO> listDevices(PageRequest pageRequest, Long userId, Integer status, String osType);

    void updateDeviceStatus(Long deviceId, Integer status);

    PageResult<AdminSubscriptionVO> listSubscriptions(PageRequest pageRequest, Long userId, String paymentStatus);

    PageResult<AdminOrderVO> listOrders(PageRequest pageRequest, Long userId, String status);

    void refundOrder(String orderNo);
}
