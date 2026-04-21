package com.lanmouse.service;

import com.lanmouse.dto.RegisterRequest;
import com.lanmouse.entity.User;

import java.util.Map;

/**
 * 用户服务接口
 */
public interface UserService {
    User register(RegisterRequest request);
    User findByPhone(String phone);
    User findById(Long id);
    boolean existsByPhone(String phone);
    boolean existsByIdCard(String idCard);
    boolean verifyPassword(String rawPassword, String encodedPassword);
    boolean validateIdCard(String idCard);
    Map<String, Object> getUserGroupInfo(Integer userGroupId);
}
