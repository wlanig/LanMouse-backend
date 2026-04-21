/**
 * LanMouse PC服务端 - 预加载脚本
 * 在渲染进程和主进程之间建立安全的IPC通信桥梁
 */

const { contextBridge, ipcRenderer } = require('electron');

// 暴露API到渲染进程
contextBridge.exposeInMainWorld('lanmouse', {
    // ========== 设置相关 ==========
    
    /**
     * 获取当前设置
     * @returns {Promise<{port: number, password: string, autoStart: boolean, startMinimized: boolean, debugMode: boolean}>}
     */
    getSettings: () => ipcRenderer.invoke('get-settings'),

    /**
     * 保存设置
     * @param {Object} settings - 要保存的设置
     * @returns {Promise<{success: boolean}>}
     */
    saveSettings: (settings) => ipcRenderer.invoke('save-settings', settings),

    // ========== 服务器相关 ==========

    /**
     * 获取服务器状态
     * @returns {Promise<{running: boolean, port: number, clients: Array}>}
     */
    getServerStatus: () => ipcRenderer.invoke('get-server-status'),

    /**
     * 启动服务器
     * @returns {Promise<{success: boolean}>}
     */
    startServer: () => ipcRenderer.invoke('start-server'),

    /**
     * 停止服务器
     * @returns {Promise<{success: boolean}>}
     */
    stopServer: () => ipcRenderer.invoke('stop-server'),

    // ========== 系统信息 ==========

    /**
     * 获取屏幕分辨率
     * @returns {Promise<{width: number, height: number, scaleFactor: number}>}
     */
    getScreenSize: () => ipcRenderer.invoke('get-screen-size'),

    /**
     * 获取鼠标控制器状态
     * @returns {Promise<{running: boolean}>}
     */
    getMouseControllerStatus: () => ipcRenderer.invoke('get-mouse-controller-status'),

    /**
     * 获取应用版本
     * @returns {Promise<string>}
     */
    getAppVersion: () => ipcRenderer.invoke('get-app-version'),

    // ========== 事件监听 ==========

    /**
     * 监听服务器启动事件
     * @param {Function} callback - 回调函数
     */
    onServerStarted: (callback) => {
        ipcRenderer.on('server-started', (event, data) => callback(data));
    },

    /**
     * 监听服务器停止事件
     * @param {Function} callback - 回调函数
     */
    onServerStopped: (callback) => {
        ipcRenderer.on('server-stopped', () => callback());
    },

    /**
     * 监听服务器错误事件
     * @param {Function} callback - 回调函数
     */
    onServerError: (callback) => {
        ipcRenderer.on('server-error', (event, error) => callback(error));
    },

    /**
     * 监听客户端连接事件
     * @param {Function} callback - 回调函数
     */
    onClientConnected: (callback) => {
        ipcRenderer.on('client-connected', (event, client) => callback(client));
    },

    /**
     * 监听客户端断开连接事件
     * @param {Function} callback - 回调函数
     */
    onClientDisconnected: (callback) => {
        ipcRenderer.on('client-disconnected', (event, client) => callback(client));
    },

    /**
     * 监听显示设置面板事件
     * @param {Function} callback - 回调函数
     */
    onShowSettings: (callback) => {
        ipcRenderer.on('show-settings', () => callback());
    },

    // ========== 事件移除 ==========

    /**
     * 移除所有事件监听器
     * @param {string} channel - 频道名称
     */
    removeAllListeners: (channel) => {
        ipcRenderer.removeAllListeners(channel);
    }
});

console.log('LanMouse preload script loaded');
