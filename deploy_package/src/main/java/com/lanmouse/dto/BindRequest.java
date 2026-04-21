package com.lanmouse.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;

@Data
public class BindRequest {

    @NotBlank(message = "绑定令牌不能为空")
    private String bindToken;
}
