-- 添加微信openid字段
-- 执行前请先备份数据库

-- 1. 添加 openid 字段（允许NULL）
ALTER TABLE users ADD COLUMN openid VARCHAR(128) DEFAULT NULL COMMENT '微信openid' AFTER password_hash;

-- 2. 创建唯一索引（可选，微信登录场景下openid应该唯一）
-- 注意：如果已有重复openid数据，需要先处理
ALTER TABLE users ADD UNIQUE INDEX idx_openid (openid);

-- 3. 如果需要将现有微信用户与手机号用户合并，可以执行以下语句：
-- UPDATE users SET openid = '已有的openid' WHERE phone = '13800138998';
