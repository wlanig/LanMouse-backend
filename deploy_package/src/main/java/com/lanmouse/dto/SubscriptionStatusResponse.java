package com.lanmouse.dto;

import java.time.LocalDate;

public class SubscriptionStatusResponse {
    private boolean active;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer daysRemaining;

    public SubscriptionStatusResponse() {}
    
    public SubscriptionStatusResponse(boolean active, LocalDate startDate, LocalDate endDate, Integer daysRemaining) {
        this.active = active;
        this.startDate = startDate;
        this.endDate = endDate;
        this.daysRemaining = daysRemaining;
    }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public Integer getDaysRemaining() { return daysRemaining; }
    public void setDaysRemaining(Integer daysRemaining) { this.daysRemaining = daysRemaining; }
}
