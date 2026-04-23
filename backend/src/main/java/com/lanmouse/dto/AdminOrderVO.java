package com.lanmouse.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class AdminOrderVO {
    private Long id;
    private String orderNo;
    private String type; // subscription or payment_qr_code
    private Long userId;
    private String userName;
    private String userPhone;
    private Long deviceId;
    private String deviceName;
    private BigDecimal amount;
    private BigDecimal discountAmount;
    private String paymentMethod;
    private String status;
    private LocalDateTime paidAt;
    private LocalDateTime expiredAt;
    private LocalDateTime createdAt;
}
