package com.lanmouse.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.lanmouse.entity.PaymentQrCode;
import org.apache.ibatis.annotations.Mapper;

/**
 * 支付二维码Mapper
 */
@Mapper
public interface PaymentQrCodeMapper extends BaseMapper<PaymentQrCode> {
}
