package com.lanmouse.dto;

import java.math.BigDecimal;

public class CreateOrderResponse {
    private String orderNo;
    private BigDecimal amount;
    private String qrCodeUrl;

    public CreateOrderResponse() {}
    
    public CreateOrderResponse(String orderNo, BigDecimal amount, String qrCodeUrl) {
        this.orderNo = orderNo;
        this.amount = amount;
        this.qrCodeUrl = qrCodeUrl;
    }

    public String getOrderNo() { return orderNo; }
    public void setOrderNo(String orderNo) { this.orderNo = orderNo; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getQrCodeUrl() { return qrCodeUrl; }
    public void setQrCodeUrl(String qrCodeUrl) { this.qrCodeUrl = qrCodeUrl; }
}
