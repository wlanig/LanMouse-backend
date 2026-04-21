-- 添加微信openid字段
-- 执行前请先备份数据库
-- 注意：init.sql 已包含 openid 字段，此脚本仅用于已有数据库的增量迁移

-- 1. 添加 openid 字段（允许NULL）
ALTER TABLE users ADD COLUMN openid VARCHAR(100) DEFAULT NULL COMMENT '微信openid' AFTER user_group_id;

-- 2. 创建索引
ALTER TABLE users ADD INDEX idx_users_openid (openid);
