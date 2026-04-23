package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StatsTrendVO {
    private String date;
    private long newUsers;
    private long newOrders;
    private BigDecimal revenue;
}
