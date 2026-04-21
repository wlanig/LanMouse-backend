# LanMouse API接口文档

## 基础信息

- 基础URL: `http://localhost:8080/api`
- 认证方式: Bearer Token (JWT)
- 数据格式: JSON
- 编码: UTF-8

## 通用响应格式

```json
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | int | 状态码，0表示成功 |
| msg | string | 消息 |
| data | object | 返回数据 |

## 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 2001 | 用户不存在 |
| 2002 | 密码错误 |
| 2003 | Token无效 |
| 2004 | 账户已禁用 |
| 3001 | 设备不存在 |
| 3002 | 设备已绑定 |
| 3003 | 绑定Token无效 |
| 4001 | 订单不存在 |
| 5001 | 权限不足 |

---

## 认证接口

### 用户注册

```
POST /api/auth/register
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| phone | string | 是 | 手机号 |
| password | string | 是 | 密码 |
| name | string | 是 | 真实姓名 |
| idCard | string | 是 | 身份证号(18位) |

**请求示例**
```json
{
  "phone": "13800138000",
  "password": "123456",
  "name": "张三",
  "idCard": "110101199001011234"
}
```

**响应示例**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "userId": 10001,
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### 用户登录

```
POST /api/auth/login
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| phone | string | 是 | 手机号 |
| password | string | 是 | 密码 |

**响应示例**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "userId": 10001,
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "idCard": "110***********1234",
    "name": "张三",
    "userGroup": {
      "id": 1,
      "name": "普通用户",
      "annualFee": 99.00
    }
  }
}
```

---

### Token刷新

```
POST /api/auth/refresh
Authorization: Bearer {token}
```

**响应示例**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### 退出登录

```
POST /api/auth/logout
Authorization: Bearer {token}
```

---

### 获取当前用户信息

```
GET /api/auth/me
Authorization: Bearer {token}
```

**响应示例**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "userId": 10001,
    "phone": "13800138000",
    "name": "张三",
    "idCard": "110***********1234",
    "userGroup": {
      "id": 1,
      "name": "普通用户",
      "annualFee": 99.00
    }
  }
}
```

---

## 设备接口

### 注册设备

```
POST /api/device/register
Authorization: Bearer {token}
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| imei1 | string | 否 | Android主IMEI |
| imei2 | string | 否 | Android副IMEI |
| iosDeviceId | string | 否 | iOS设备ID |
| deviceName | string | 是 | 设备名称 |
| deviceModel | string | 否 | 设备型号 |
| osType | string | 是 | 操作系统 (ios/android) |
| osVersion | string | 否 | 系统版本 |

**响应示例**
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "deviceId": 20001,
    "bindToken": "abc123def456",
    "pcServicePort": 19876
  }
}
```

---

### 绑定设备

```
POST /api/device/bind
Authorization: Bearer {token}
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| bindToken | string | 是 | 绑定令牌 |

**响应示例**
```json
{
  "code": 0,
  "msg": "绑定成功"
}
```

---

### 获取设备列表

```
GET /api/device/list
Authorization: Bearer {token}
```

**响应示例**
```json
{
  "code": 0,
  "data": [
    {
      "deviceId": 20001,
      "deviceName": "我的手机",
      "deviceModel": "Xiaomi 13",
      "osType": "android",
      "osVersion": "14",
      "status": 1,
      "lastIp": "192.168.1.100",
      "lastActiveAt": "2026-04-18 10:00:00",
      "subscription": {
        "subscribed": true,
        "endDate": "2027-04-18",
        "daysRemaining": 365,
        "status": "active"
      }
    }
  ]
}
```

---

### 获取设备详情

```
GET /api/device/{deviceId}
Authorization: Bearer {token}
```

---

### 解绑设备

```
POST /api/device/{deviceId}/unbind
Authorization: Bearer {token}
```

---

### 更新设备信息

```
PUT /api/device/{deviceId}
Authorization: Bearer {token}
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| deviceName | string | 否 | 设备名称 |
| deviceModel | string | 否 | 设备型号 |

---

### 设备心跳

```
POST /api/device/{deviceId}/heartbeat
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| ip | string | 是 | 当前IP地址 |

---

## 订阅接口

### 创建订阅订单

```
POST /api/subscription/create-order
Authorization: Bearer {token}
```

**请求参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| deviceId | long | 是 | 设备ID |

**响应示例**
```json
{
  "code": 0,
  "data": {
    "orderNo": "SUB202604180001",
    "amount": 99.00,
    "originalAmount": 99.00,
    "discountAmount": 0.00,
    "qrCodeUrl": "https://api.lanmouse.com/payment/qr/xxx",
    "qrCodeData": "https://pay.lanmouse.com?order=xxx",
    "expireMinutes": 30
  }
}
```

---

### 获取订阅状态

```
GET /api/subscription/status/{deviceId}
Authorization: Bearer {token}
```

**响应示例**
```json
{
  "code": 0,
  "data": {
    "subscribed": true,
    "endDate": "2027-04-18",
    "daysRemaining": 365,
    "autoRenew": false
  }
}
```

---

### 支付回调

```
POST /api/subscription/callback/{orderNo}
```

**请求参数**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| status | string | paid/expired |

---

### 查询订单状态

```
GET /api/subscription/order/{orderNo}
```

---

### 获取订单列表

```
GET /api/subscription/orders?page=1&size=10
Authorization: Bearer {token}
```

---

### 取消订单

```
POST /api/subscription/cancel/{orderNo}
Authorization: Bearer {token}
```

---

## PC端验证接口

### 验证订阅

```
GET /api/verify/subscription?deviceId={deviceId}&imei={imei}
```

**响应示例**
```json
{
  "code": 0,
  "data": {
    "valid": true,
    "endDate": "2027-04-18",
    "daysRemaining": 365
  }
}
```

---

### 批量验证设备

```
POST /api/verify/batch
Content-Type: application/json

{
  "devices": [
    {"deviceId": 20001, "imei": "861234567890123"},
    {"deviceId": 20002, "imei": "861234567890124"}
  ]
}
```

---

## 身份证号格式说明

身份证号必须为18位，格式如下：

```
XXXXXXXXXXXXXXXXXX
││││││││ ││││││││
省 市区  年  月  日  顺序码 校验码
```

### 校验规则

1. **前17位**必须为数字
2. **最后一位**可以为数字或X/x
3. **地区码**必须是有效代码
4. **出生日期**必须是有效日期（YYYYMMDD）
5. **校验码**必须符合加权求和模11规则

### 校验码计算

```
加权因子: [7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2]
校验码:   ['1','0','X','9','8','7','6','5','4','3','2']

计算: Σ(ai × Wi) % 11 的映射值 == A18
```
