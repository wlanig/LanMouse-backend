package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("subscriptions")
public class Subscription {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 设备ID
     */
    private Long deviceId;

    /**
     * 订单号
     */
    private String orderNo;

    /**
     * 有效期开始
     */
    private LocalDate startDate;

    /**
     * 有效期结束
     */
    private LocalDate endDate;

    /**
     * 实际金额
     */
    private BigDecimal amount;

    /**
     * 优惠金额
     */
    private BigDecimal discountAmount;

    /**
     * 支付方式
     */
    private String paymentMethod;

    /**
     * 支付状态
     */
    private String paymentStatus;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    /**
     * 更新时间
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
