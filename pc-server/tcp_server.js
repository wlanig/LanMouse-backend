/**
 * LanMouse PC服务端 - TCP Socket 服务器
 * 处理手机端触控板指令的接收和解析
 */

const net = require('net');
const { v4: uuidv4 } = require('uuid');
const log = require('electron-log');

class TCPServer {
    constructor(options = {}) {
        this.port = options.port || 19876;
        this.password = options.password || '';
        this.mouseController = options.mouseController;
        this.onClientConnect = options.onClientConnect || (() => {});
        this.onClientDisconnect = options.onClientDisconnect || (() => {});
        this.onError = options.onError || ((err) => log.error('TCP Server error:', err));

        this.server = null;
        this.clients = new Map();
        this.isRunning = false;
        this.heartbeatInterval = null;

        // 屏幕分辨率（从主进程获取）
        this.screenWidth = 1920;
        this.screenHeight = 1080;

        log.info('TCPServer initialized with port:', this.port);
    }

    /**
     * 启动TCP服务器
     * @param {Function} callback - 启动完成回调 (success, error)
     */
    start(callback) {
        if (this.isRunning) {
            log.warn('TCP server is already running');
            if (callback) callback(true);
            return;
        }

        try {
            this.server = net.createServer((socket) => {
                this.handleConnection(socket);
            });

            this.server.on('error', (err) => {
                log.error('TCP server error:', err);
                this.isRunning = false;
                if (this.onError) this.onError(err);
                if (callback) callback(false, err);
            });

            this.server.listen(this.port, '0.0.0.0', () => {
                log.info(`TCP server listening on port ${this.port}`);
                this.isRunning = true;
                
                // 启动心跳检测
                this.startHeartbeat();
                
                if (callback) callback(true);
            });

        } catch (err) {
            log.error('Failed to start TCP server:', err);
            this.isRunning = false;
            if (callback) callback(false, err);
        }
    }

    /**
     * 停止TCP服务器
     */
    stop() {
        log.info('Stopping TCP server...');
        
        // 停止心跳检测
        this.stopHeartbeat();

        // 关闭所有客户端连接
        for (const [id, client] of this.clients) {
            try {
                client.socket.destroy();
            } catch (e) {
                log.warn(`Error closing client ${id}:`, e);
            }
        }
        this.clients.clear();

        // 关闭服务器
        if (this.server) {
            this.server.close((err) => {
                if (err) {
                    log.error('Error closing TCP server:', err);
                } else {
                    log.info('TCP server stopped');
                }
            });
            this.server = null;
        }

        this.isRunning = false;
    }

    /**
     * 处理新的客户端连接
     * @param {net.Socket} socket - 客户端socket
     */
    handleConnection(socket) {
        const clientId = uuidv4();
        const clientInfo = {
            id: clientId,
            socket: socket,
            ip: socket.remoteAddress,
            port: socket.remotePort,
            name: `设备-${clientId.substring(0, 8)}`,
            authenticated: false,
            lastHeartbeat: Date.now()
        };

        log.info(`New client connected: ${clientInfo.ip}:${clientInfo.port} (${clientId})`);

        // 添加到客户端列表
        this.clients.set(clientId, clientInfo);

        // 发送欢迎消息
        this.sendToClient(clientId, {
            type: 'welcome',
            serverVersion: '1.0.0',
            requireAuth: this.password !== ''
        });

        // 数据接收处理
        let buffer = '';
        
        socket.on('data', (data) => {
            buffer += data.toString();
            
            // 处理粘包：按换行符分割
            const lines = buffer.split('\n');
            buffer = lines.pop(); // 保留最后一行（可能不完整）
            
            for (const line of lines) {
                if (line.trim()) {
                    this.handleClientMessage(clientId, line.trim());
                }
            }
        });

        // 客户端断开连接
        socket.on('close', () => {
            log.info(`Client disconnected: ${clientInfo.ip} (${clientId})`);
            this.clients.delete(clientId);
            if (this.onClientDisconnect) this.onClientDisconnect(clientInfo);
        });

        // 客户端错误
        socket.on('error', (err) => {
            log.error(`Client ${clientId} error:`, err.message);
            this.clients.delete(clientId);
        });

        // 通知主进程
        if (this.onClientConnect) this.onClientConnect(clientInfo);
    }

    /**
     * 处理客户端消息
     * @param {string} clientId - 客户端ID
     * @param {string} message - 消息内容（JSON字符串）
     */
    handleClientMessage(clientId, message) {
        const client = this.clients.get(clientId);
        if (!client) return;

        try {
            const data = JSON.parse(message);
            log.debug(`Received from ${clientId}:`, data);

            // 验证密码
            if (this.password && !client.authenticated) {
                if (data.type === 'auth') {
                    if (data.password === this.password) {
                        client.authenticated = true;
                        client.name = data.deviceName || client.name;
                        this.sendToClient(clientId, {
                            type: 'auth_success',
                            clientId: clientId
                        });
                        log.info(`Client ${clientId} authenticated as ${client.name}`);
                    } else {
                        this.sendToClient(clientId, {
                            type: 'auth_failed',
                            reason: 'Invalid password'
                        });
                        client.socket.destroy();
                    }
                } else {
                    this.sendToClient(clientId, {
                        type: 'error',
                        message: 'Authentication required'
                    });
                    client.socket.destroy();
                }
                return;
            }

            // 更新心跳时间
            client.lastHeartbeat = Date.now();

            // 处理不同类型的消息
            switch (data.type) {
                case 'auth':
                    // 已经在上面处理
                    break;

                case 'heartbeat':
                    this.sendToClient(clientId, {
                        type: 'heartbeat_ack',
                        timestamp: Date.now()
                    });
                    break;

                case 'device_info':
                    client.name = data.name || client.name;
                    client.deviceType = data.deviceType;
                    client.osVersion = data.osVersion;
                    break;

                case 'mouse_move':
                    this.handleMouseMove(clientId, data);
                    break;

                case 'mouse_click':
                    this.handleMouseClick(clientId, data);
                    break;

                case 'mouse_scroll':
                    this.handleMouseScroll(clientId, data);
                    break;

                case 'mouse_drag':
                    this.handleMouseDrag(clientId, data);
                    break;

                case 'mouse_position':
                    this.handleMousePosition(clientId);
                    break;

                default:
                    log.warn(`Unknown message type: ${data.type}`);
                    this.sendToClient(clientId, {
                        type: 'error',
                        message: `Unknown message type: ${data.type}`
                    });
            }

        } catch (err) {
            log.error(`Error parsing message from ${clientId}:`, err.message);
            log.debug(`Raw message: ${message}`);
        }
    }

    /**
     * 处理鼠标移动
     * @param {string} clientId - 客户端ID
     * @param {Object} data - 移动数据
     */
    handleMouseMove(clientId, data) {
        let { x, y, dx, dy, mode } = data;

        // mode: 'absolute' 或 'relative'
        mode = mode || 'relative';

        if (mode === 'absolute') {
            // 绝对坐标：将 0-100 转换为屏幕坐标
            const targetX = Math.round((x / 100) * this.screenWidth);
            const targetY = Math.round((y / 100) * this.screenHeight);
            
            if (this.mouseController) {
                this.mouseController.moveMouse(targetX, targetY);
            }
        } else {
            // 相对坐标：将 0-100 转换为像素位移（缩放）
            const pixelDx = Math.round(dx * 10); // 调整灵敏度
            const pixelDy = Math.round(dy * 10);
            
            // Windows 下使用相对移动（通过 Python 脚本）
            if (this.mouseController) {
                this.mouseController.moveMouse(pixelDx, pixelDy);
            }
        }

        log.debug(`Mouse move: mode=${mode}, x=${x}, y=${y}, dx=${dx}, dy=${dy}`);
    }

    /**
     * 处理鼠标点击
     * @param {string} clientId - 客户端ID
     * @param {Object} data - 点击数据
     */
    handleMouseClick(clientId, data) {
        const button = data.button || 'left';
        const x = data.x;
        const y = data.y;

        // 如果提供了坐标，先移动到该位置
        if (x !== undefined && y !== undefined) {
            const targetX = Math.round((x / 100) * this.screenWidth);
            const targetY = Math.round((y / 100) * this.screenHeight);
            if (this.mouseController) {
                this.mouseController.moveMouse(targetX, targetY);
            }
        }

        // 执行点击
        if (this.mouseController) {
            if (data.double) {
                // 双击
                this.mouseController.click(button);
                setTimeout(() => {
                    this.mouseController.click(button);
                }, 100);
            } else {
                this.mouseController.click(button);
            }
        }

        log.debug(`Mouse click: button=${button}, double=${data.double || false}`);
    }

    /**
     * 处理鼠标滚动
     * @param {string} clientId - 客户端ID
     * @param {Object} data - 滚动数据
     */
    handleMouseScroll(clientId, data) {
        const scrollY = data.scrollY || 0;

        if (this.mouseController) {
            this.mouseController.scroll(scrollY);
        }

        log.debug(`Mouse scroll: scrollY=${scrollY}`);
    }

    /**
     * 处理鼠标拖拽
     * @param {string} clientId - 客户端ID
     * @param {Object} data - 拖拽数据
     */
    handleMouseDrag(clientId, data) {
        const { startX, startY, endX, endY } = data;

        // 转换坐标
        const startX_px = Math.round((startX / 100) * this.screenWidth);
        const startY_px = Math.round((startY / 100) * this.screenHeight);
        const endX_px = Math.round((endX / 100) * this.screenWidth);
        const endY_px = Math.round((endY / 100) * this.screenHeight);

        if (this.mouseController) {
            this.mouseController.drag(startX_px, startY_px, endX_px, endY_px);
        }

        log.debug(`Mouse drag: (${startX},${startY}) -> (${endX},${endY})`);
    }

    /**
     * 处理获取鼠标位置请求
     * @param {string} clientId - 客户端ID
     */
    handleMousePosition(clientId) {
        // 注意：获取当前鼠标位置需要使用额外的机制
        // 这里简单返回中心点作为占位
        this.sendToClient(clientId, {
            type: 'mouse_position_response',
            x: 50,
            y: 50,
            timestamp: Date.now()
        });
    }

    /**
     * 向指定客户端发送消息
     * @param {string} clientId - 客户端ID
     * @param {Object} data - 要发送的数据
     */
    sendToClient(clientId, data) {
        const client = this.clients.get(clientId);
        if (client && client.socket && !client.socket.destroyed) {
            try {
                client.socket.write(JSON.stringify(data) + '\n');
            } catch (err) {
                log.error(`Error sending to client ${clientId}:`, err.message);
            }
        }
    }

    /**
     * 广播消息到所有客户端
     * @param {Object} data - 要发送的数据
     */
    broadcast(data) {
        for (const [clientId] of this.clients) {
            this.sendToClient(clientId, data);
        }
    }

    /**
     * 启动心跳检测
     */
    startHeartbeat() {
        this.heartbeatInterval = setInterval(() => {
            const now = Date.now();
            const timeout = 60000; // 60秒超时

            for (const [clientId, client] of this.clients) {
                if (now - client.lastHeartbeat > timeout) {
                    log.warn(`Client ${clientId} heartbeat timeout, disconnecting`);
                    client.socket.destroy();
                    this.clients.delete(clientId);
                    if (this.onClientDisconnect) this.onClientDisconnect(client);
                } else {
                    // 发送心跳请求
                    this.sendToClient(clientId, {
                        type: 'heartbeat_request',
                        timestamp: now
                    });
                }
            }
        }, 30000); // 每30秒检测一次
    }

    /**
     * 停止心跳检测
     */
    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }

    /**
     * 检查服务器是否正在运行
     * @returns {boolean}
     */
    isRunningServer() {
        return this.isRunning;
    }

    /**
     * 获取所有已连接的客户端
     * @returns {Array} 客户端信息列表
     */
    getConnectedClients() {
        const clients = [];
        for (const [id, client] of this.clients) {
            clients.push({
                id: id,
                name: client.name,
                ip: client.ip,
                deviceType: client.deviceType,
                osVersion: client.osVersion
            });
        }
        return clients;
    }

    /**
     * 设置屏幕分辨率
     * @param {number} width - 屏幕宽度
     * @param {number} height - 屏幕高度
     */
    setScreenSize(width, height) {
        this.screenWidth = width;
        this.screenHeight = height;
        log.info(`Screen size set to ${width}x${height}`);
    }
}

module.exports = TCPServer;
