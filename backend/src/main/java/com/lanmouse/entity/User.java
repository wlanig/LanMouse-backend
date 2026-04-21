package com.lanmouse.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("users")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 身份证号（明文，用于显示）
     */
    private String idCard;

    /**
     * 身份证号哈希（存储校验用）
     */
    private String idCardHash;

    /**
     * 真实姓名
     */
    private String name;

    /**
     * 手机号（唯一）
     */
    private String phone;

    /**
     * 密码哈希（BCrypt加密）
     */
    private String passwordHash;

    /**
     * 用户组ID
     */
    private Integer userGroupId;

    /**
     * 状态：0-禁用 1-正常
     */
    private Integer status;

    /**
     * 微信openid（用于微信登录）
     */
    private String openid;

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
