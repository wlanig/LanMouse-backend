package com.lanmouse.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * 微信小程序服务
 */
@Service
public class WechatService {

    private static final Logger log = LoggerFactory.getLogger(WechatService.class);

    @Value("${wechat.appid}")
    private String appid;

    @Value("${wechat.secret}")
    private String secret;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public WechatService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * 通过code获取微信openid
     */
    public String getOpenid(String code) {
        try {
            String url = String.format(
                "https://api.weixin.qq.com/sns/jscode2session?appid=%s&secret=%s&js_code=%s&grant_type=authorization_code",
                appid, secret, code
            );

            String response = restTemplate.getForObject(url, String.class);
            log.debug("微信API响应: {}", response);

            JsonNode jsonNode = objectMapper.readTree(response);

            if (jsonNode.has("openid")) {
                return jsonNode.get("openid").asText();
            } else if (jsonNode.has("errcode")) {
                int errcode = jsonNode.get("errcode").asInt();
                String errmsg = jsonNode.has("errmsg") ? jsonNode.get("errmsg").asText() : "未知错误";
                log.error("微信API错误: errcode={}, errmsg={}", errcode, errmsg);
                throw new RuntimeException("微信登录失败: " + errmsg);
            }

            return null;
        } catch (Exception e) {
            log.error("获取openid失败", e);
            throw new RuntimeException("获取openid失败: " + e.getMessage());
        }
    }

    /**
     * 获取用户手机号
     */
    public Map<String, Object> getPhoneNumber(String accessToken, String code) {
        try {
            String url = "https://api.weixin.qq.com/wxa/business/getuserphonenumber?access_token=" + accessToken;

            Map<String, String> requestBody = new HashMap<>();
            requestBody.put("code", code);

            String response = restTemplate.postForObject(url, requestBody, String.class);
            log.debug("获取手机号响应: {}", response);

            JsonNode jsonNode = objectMapper.readTree(response);
            Map<String, Object> result = new HashMap<>();

            if (jsonNode.has("phone_info")) {
                JsonNode phoneInfo = jsonNode.get("phone_info");
                result.put("phoneNumber", phoneInfo.has("phoneNumber") ? phoneInfo.get("phoneNumber").asText() : null);
                result.put("countryCode", phoneInfo.has("countryCode") ? phoneInfo.get("countryCode").asText() : null);
            } else {
                result.put("error", jsonNode.has("errmsg") ? jsonNode.get("errmsg").asText() : "获取手机号失败");
            }

            return result;
        } catch (Exception e) {
            log.error("获取手机号失败", e);
            Map<String, Object> error = new HashMap<>();
            error.put("error", "获取手机号失败: " + e.getMessage());
            return error;
        }
    }
}
