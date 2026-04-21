package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("devices")
public class Device {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * IMEI1（主要）
     */
    private String imei1;

    /**
     * IMEI2
     */
    private String imei2;

    /**
     * iOS设备ID
     */
    private String iosDeviceId;

    /**
     * 设备名称
     */
    private String deviceName;

    /**
     * 设备型号
     */
    private String deviceModel;

    /**
     * 操作系统类型：ios/android
     */
    private String osType;

    /**
     * 系统版本
     */
    private String osVersion;

    /**
     * 最后连接IP
     */
    private String lastIp;

    /**
     * 最后活跃时间
     */
    private LocalDateTime lastActiveAt;

    /**
     * 状态：0-未激活 1-正常 2-冻结
     */
    private Integer status;

    /**
     * 绑定令牌（用于PC端绑定）
     */
    private String bindToken;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
