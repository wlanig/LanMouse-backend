package com.lanmouse.dto;

import lombok.Data;
import javax.validation.constraints.NotNull;

@Data
public class CreateOrderRequest {

    @NotNull(message = "设备ID不能为空")
    private Long deviceId;
}
