package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class VerifySubscriptionResponse {

    private Boolean valid;
    private String endDate;
    private Integer daysRemaining;
}
