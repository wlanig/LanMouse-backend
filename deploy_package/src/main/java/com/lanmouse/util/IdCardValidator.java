package com.lanmouse.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

/**
 * 身份证号工具类
 */
public class IdCardValidator {

    // 权重值
    private static final int[] WEIGHT = {7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2};

    // 校验码
    private static final char[] CHECK_CODE = {'1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'};

    // 有效的省份代码（简化版）
    private static final String[] PROVINCE_CODES = {
        "11", "12", "13", "14", "15",
        "21", "22", "23",
        "31", "32", "33", "34", "35", "36", "37",
        "41", "42", "43", "44", "45", "46",
        "50", "51", "52", "53", "54",
        "61", "62", "63", "64", "65",
        "71", "81", "82"
    };

    /**
     * 验证身份证号合法性
     *
     * @param idCard 身份证号
     * @return 是否合法
     */
    public static boolean isValid(String idCard) {
        if (idCard == null || idCard.length() != 18) {
            return false;
        }

        // 格式验证
        if (!idCard.matches("^\\d{17}[\\dXx]$")) {
            return false;
        }

        // 省份验证
        String provinceCode = idCard.substring(0, 2);
        if (!isValidProvinceCode(provinceCode)) {
            return false;
        }

        // 出生日期验证
        String birthDateStr = idCard.substring(6, 14);
        if (!isValidBirthDate(birthDateStr)) {
            return false;
        }

        // 校验码验证
        return validateCheckCode(idCard);
    }

    /**
     * 验证省份代码
     */
    private static boolean isValidProvinceCode(String code) {
        for (String validCode : PROVINCE_CODES) {
            if (validCode.equals(code)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 验证出生日期
     */
    private static boolean isValidBirthDate(String dateStr) {
        try {
            LocalDate birthDate = LocalDate.parse(dateStr, DateTimeFormatter.ofPattern("yyyyMMdd"));

            // 检查日期是否在过去和未来合理范围内
            LocalDate now = LocalDate.now();
            if (birthDate.isAfter(now) || birthDate.isBefore(now.minusYears(150))) {
                return false;
            }

            return true;
        } catch (DateTimeParseException e) {
            return false;
        }
    }

    /**
     * 验证校验码
     */
    private static boolean validateCheckCode(String idCard) {
        int sum = 0;
        for (int i = 0; i < 17; i++) {
            sum += Character.getNumericValue(idCard.charAt(i)) * WEIGHT[i];
        }

        int index = sum % 11;
        char expectedCheckCode = CHECK_CODE[index];
        char actualCheckCode = Character.toUpperCase(idCard.charAt(17));

        return expectedCheckCode == actualCheckCode;
    }

    /**
     * 从身份证号提取出生日期
     *
     * @param idCard 身份证号
     * @return 出生日期 (yyyy-MM-dd)
     */
    public static String getBirthDate(String idCard) {
        if (!isValid(idCard)) {
            return null;
        }
        String dateStr = idCard.substring(6, 14);
        return dateStr.substring(0, 4) + "-" + dateStr.substring(4, 6) + "-" + dateStr.substring(6, 8);
    }

    /**
     * 从身份证号提取性别
     *
     * @param idCard 身份证号
     * @return "M" (男) 或 "F" (女)
     */
    public static String getGender(String idCard) {
        if (idCard.length() != 18) {
            return null;
        }
        int genderDigit = Character.getNumericValue(idCard.charAt(16));
        return (genderDigit % 2 == 0) ? "F" : "M";
    }

    /**
     * 从身份证号提取年龄
     *
     * @param idCard 身份证号
     * @return 年龄
     */
    public static int getAge(String idCard) {
        String birthDateStr = idCard.substring(6, 14);
        try {
            LocalDate birthDate = LocalDate.parse(birthDateStr, DateTimeFormatter.ofPattern("yyyyMMdd"));
            LocalDate now = LocalDate.now();
            int age = now.getYear() - birthDate.getYear();
            if (now.getDayOfYear() < birthDate.getDayOfYear()) {
                age--;
            }
            return age;
        } catch (DateTimeParseException e) {
            return 0;
        }
    }

    /**
     * 掩码身份证号（脱敏）
     *
     * @param idCard 身份证号
     * @return 掩码后的身份证号
     */
    public static String mask(String idCard) {
        if (idCard == null || idCard.length() < 8) {
            return "**************";
        }
        return idCard.substring(0, 3) + "********" + idCard.substring(idCard.length() - 4);
    }

    public static String maskIdCard(String idCard) {
        return mask(idCard);
    }

    public static String hashIdCard(String idCard) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((idCard + "lanmouse_salt").getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }

    /**
     * 获取身份证归属地
     *
     * @param idCard 身份证号
     * @return 归属地（简化版）
     */
    public static String getProvince(String idCard) {
        if (idCard == null || idCard.length() < 2) {
            return "未知";
        }

        String provinceCode = idCard.substring(0, 2);
        return getProvinceName(provinceCode);
    }

    private static String getProvinceName(String code) {
        switch (code) {
            case "11": return "北京市";
            case "12": return "天津市";
            case "13": return "河北省";
            case "14": return "山西省";
            case "15": return "内蒙古";
            case "21": return "辽宁省";
            case "22": return "吉林省";
            case "23": return "黑龙江省";
            case "31": return "上海市";
            case "32": return "江苏省";
            case "33": return "浙江省";
            case "34": return "安徽省";
            case "35": return "福建省";
            case "36": return "江西省";
            case "37": return "山东省";
            case "41": return "河南省";
            case "42": return "湖北省";
            case "43": return "湖南省";
            case "44": return "广东省";
            case "45": return "广西";
            case "46": return "海南省";
            case "50": return "重庆市";
            case "51": return "四川省";
            case "52": return "贵州省";
            case "53": return "云南省";
            case "54": return "西藏";
            case "61": return "陕西省";
            case "62": return "甘肃省";
            case "63": return "青海省";
            case "64": return "宁夏";
            case "65": return "新疆";
            case "71": return "台湾";
            case "81": return "香港";
            case "82": return "澳门";
            default: return "未知";
        }
    }
}
