class AppConfig {
  // API服务器地址
  static const String apiBaseUrl = 'http://localhost:8080';
  
  // API端口
  static const int apiPort = 8080;
  
  // PC服务端默认端口
  static const int pcServicePort = 19876;
  
  // UDP广播端口(用于发现PC服务端)
  static const int discoveryPort = 19877;
  
  // Socket连接超时时间(毫秒)
  static const int socketTimeout = 5000;
  
  // 心跳间隔(毫秒)
  static const int heartbeatInterval = 3000;
  
  // 连接重试次数
  static const int maxRetryAttempts = 3;
  
  // 二维码过期时间(分钟)
  static const int qrCodeExpireMinutes = 30;
  
  // 应用名称
  static const String appName = 'LanMouse';
  
  // 应用版本
  static const String appVersion = '1.0.0';
}
