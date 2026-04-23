package com.lanmouse.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * JWT工具类
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    /**
     * 生成Token（普通用户）
     */
    public String generateToken(Long userId, String phone) {
        return generateToken(userId, phone, "user");
    }

    /**
     * 生成Token（指定角色）
     */
    public String generateToken(Long userId, String phone, String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("phone", phone);
        claims.put("role", role);

        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * 从Token获取用户ID
     */
    public Long getUserIdFromToken(String token) {
        try {
            Claims claims = parseToken(token);
            return claims.get("userId", Long.class);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 从Token获取手机号
     */
    public String getPhoneFromToken(String token) {
        try {
            Claims claims = parseToken(token);
            return claims.get("phone", String.class);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 验证Token
     */
    public boolean validateToken(String token) {
        try {
            parseToken(token);
            return true;
        } catch (JwtException e) {
            return false;
        }
    }

    /**
     * 从Token获取角色
     */
    public String getRoleFromToken(String token) {
        try {
            Claims claims = parseToken(token);
            return claims.getOrDefault("role", "user").toString();
        } catch (Exception e) {
            return "user";
        }
    }

    /**
     * 刷新Token
     */
    public String refreshToken(String token) {
        try {
            Claims claims = parseToken(token);
            Long userId = claims.get("userId", Long.class);
            String phone = claims.get("phone", String.class);
            String role = claims.getOrDefault("role", "user").toString();
            return generateToken(userId, phone, role);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 解析Token
     */
    private Claims parseToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /**
     * 获取签名密钥
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
