package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderResponse {

    private String orderNo;
    private String amount;
    private String discountAmount;
    private String qrCodeUrl;
    private Integer expireMinutes;
}
