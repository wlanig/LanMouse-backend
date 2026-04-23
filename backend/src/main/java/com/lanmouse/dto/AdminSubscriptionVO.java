package com.lanmouse.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
public class AdminSubscriptionVO {
    private Long id;
    private Long userId;
    private String userName;
    private String userPhone;
    private Long deviceId;
    private String deviceName;
    private String orderNo;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal amount;
    private BigDecimal discountAmount;
    private String paymentMethod;
    private String paymentStatus;
    private LocalDateTime createdAt;
    private long daysRemaining;
}
