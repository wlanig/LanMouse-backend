package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StatsOverviewVO {
    private long totalUsers;
    private long totalDevices;
    private long totalOrders;
    private long activeSubscriptions;
    private BigDecimal totalRevenue;
    private long todayNewUsers;
    private long todayNewOrders;
}
