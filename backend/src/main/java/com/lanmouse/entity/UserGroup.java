package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;

@Data
@TableName("user_groups")
public class UserGroup {

    @TableId(type = IdType.AUTO)
    private Integer id;

    /**
     * 组名称
     */
    private String name;

    /**
     * 组代码
     */
    private String code;

    /**
     * 年费标准价
     */
    private BigDecimal annualFee;

    /**
     * 折扣率(0.00-1.00)
     */
    private BigDecimal discountRate;

    /**
     * 描述
     */
    private String description;

    /**
     * 状态：0-禁用 1-正常
     */
    private Integer status;
}
