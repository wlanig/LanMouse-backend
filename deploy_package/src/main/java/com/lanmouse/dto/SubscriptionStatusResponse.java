package com.lanmouse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionStatusResponse {

    private Boolean subscribed;
    private String endDate;
    private Integer daysRemaining;
    private Boolean autoRenew;
}
