package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("payment_qr_codes")
public class PaymentQrCode {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 二维码内容
     */
    private String qrCode;

    /**
     * 关联订单号
     */
    private String orderNo;

    /**
     * 金额
     */
    private BigDecimal amount;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 设备ID
     */
    private Long deviceId;

    /**
     * 状态：pending/paid/expired
     */
    private String status;

    /**
     * 过期时间
     */
    private LocalDateTime expiredAt;

    /**
     * 支付时间
     */
    private LocalDateTime paidAt;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
