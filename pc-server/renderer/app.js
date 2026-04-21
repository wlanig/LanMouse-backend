/**
 * LanMouse PC服务端 - 渲染进程脚本
 * 处理UI交互和与主进程的IPC通信
 */

// 日志缓存
const logCache = [];
const MAX_LOG_ENTRIES = 100;

// DOM元素缓存
const elements = {
    appVersion: document.getElementById('appVersion'),
    statusIndicator: document.getElementById('statusIndicator'),
    serverPort: document.getElementById('serverPort'),
    connectedDevices: document.getElementById('connectedDevices'),
    mouseControllerStatus: document.getElementById('mouseControllerStatus'),
    toggleServerBtn: document.getElementById('toggleServerBtn'),
    devicesList: document.getElementById('devicesList'),
    refreshDevicesBtn: document.getElementById('refreshDevicesBtn'),
    settingsPanel: document.getElementById('settingsPanel'),
    openSettingsBtn: document.getElementById('openSettingsBtn'),
    closeSettingsBtn: document.getElementById('closeSettingsBtn'),
    settingsForm: document.getElementById('settingsForm'),
    portInput: document.getElementById('portInput'),
    passwordInput: document.getElementById('passwordInput'),
    autoStartCheck: document.getElementById('autoStartCheck'),
    startMinimizedCheck: document.getElementById('startMinimizedCheck'),
    debugModeCheck: document.getElementById('debugModeCheck'),
    cancelSettingsBtn: document.getElementById('cancelSettingsBtn'),
    showLogsBtn: document.getElementById('showLogsBtn'),
    logPanel: document.getElementById('logPanel'),
    logContent: document.getElementById('logContent'),
    closeLogsBtn: document.getElementById('closeLogsBtn'),
    clearLogsBtn: document.getElementById('clearLogsBtn'),
    saveLogsBtn: document.getElementById('saveLogsBtn')
};

// 连接设备列表
let connectedClients = [];

/**
 * 添加日志条目
 * @param {string} message - 日志消息
 * @param {string} level - 日志级别 'info' | 'warn' | 'error'
 */
function addLog(message, level = 'info') {
    const time = new Date().toLocaleTimeString();
    const entry = { time, message, level };
    
    logCache.push(entry);
    if (logCache.length > MAX_LOG_ENTRIES) {
        logCache.shift();
    }
    
    renderLogs();
}

/**
 * 渲染日志列表
 */
function renderLogs() {
    elements.logContent.innerHTML = logCache.map(entry => `
        <div class="log-entry ${entry.level}">
            <span class="log-time">[${entry.time}]</span>
            ${entry.message}
        </div>
    `).join('');
    
    // 滚动到底部
    elements.logContent.scrollTop = elements.logContent.scrollHeight;
}

/**
 * 更新服务器状态UI
 * @param {boolean} running - 服务器是否运行中
 * @param {number} port - 服务器端口
 */
function updateServerStatus(running, port) {
    const indicator = elements.statusIndicator;
    const statusText = indicator.querySelector('.status-text');
    const btn = elements.toggleServerBtn;
    
    if (running) {
        indicator.classList.add('running');
        statusText.textContent = '运行中';
        btn.innerHTML = '<span class="btn-icon">⏹</span>停止服务';
        btn.classList.add('btn-danger');
        btn.classList.remove('btn-primary');
    } else {
        indicator.classList.remove('running');
        statusText.textContent = '已停止';
        btn.innerHTML = '<span class="btn-icon">▶</span>启动服务';
        btn.classList.remove('btn-danger');
        btn.classList.add('btn-primary');
    }
    
    elements.serverPort.textContent = port || '19876';
}

/**
 * 更新连接设备列表UI
 * @param {Array} clients - 已连接设备列表
 */
function updateDevicesList(clients) {
    connectedClients = clients;
    elements.connectedDevices.textContent = clients.length;
    
    if (clients.length === 0) {
        elements.devicesList.innerHTML = `
            <div class="empty-state">
                <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                    <rect x="8" y="12" width="32" height="24" rx="2" stroke="#999" stroke-width="2"/>
                    <circle cx="24" cy="24" r="6" stroke="#999" stroke-width="2"/>
                </svg>
                <p>暂无连接设备</p>
                <small>请使用手机客户端连接</small>
            </div>
        `;
        return;
    }
    
    const deviceIcons = {
        'android': '📱',
        'ios': '📱',
        'windows': '💻',
        'mac': '💻',
        'linux': '🖥️',
        'default': '📱'
    };
    
    elements.devicesList.innerHTML = clients.map(client => {
        const icon = deviceIcons[client.deviceType] || deviceIcons.default;
        return `
            <div class="device-item">
                <div class="device-icon">${icon}</div>
                <div class="device-info">
                    <div class="device-name">${escapeHtml(client.name || '未知设备')}</div>
                    <div class="device-ip">${escapeHtml(client.ip || 'N/A')}</div>
                </div>
                <div class="device-status"></div>
            </div>
        `;
    }).join('');
}

/**
 * HTML转义，防止XSS
 * @param {string} text - 原始文本
 * @returns {string} 转义后的文本
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * 加载设置
 */
async function loadSettings() {
    try {
        const settings = await window.lanmouse.getSettings();
        
        elements.portInput.value = settings.port || 19876;
        elements.passwordInput.value = settings.password || '';
        elements.autoStartCheck.checked = settings.autoStart || false;
        elements.startMinimizedCheck.checked = settings.startMinimized || false;
        elements.debugModeCheck.checked = settings.debugMode || false;
        
        addLog('设置已加载', 'info');
    } catch (err) {
        addLog(`加载设置失败: ${err.message}`, 'error');
    }
}

/**
 * 保存设置
 */
async function saveSettings() {
    const settings = {
        port: parseInt(elements.portInput.value) || 19876,
        password: elements.passwordInput.value || '',
        autoStart: elements.autoStartCheck.checked,
        startMinimized: elements.startMinimizedCheck.checked,
        debugMode: elements.debugModeCheck.checked
    };
    
    // 验证端口
    if (settings.port < 1024 || settings.port > 65535) {
        addLog('端口必须在1024-65535之间', 'warn');
        return;
    }
    
    try {
        await window.lanmouse.saveSettings(settings);
        addLog('设置已保存', 'info');
        hideSettingsPanel();
    } catch (err) {
        addLog(`保存设置失败: ${err.message}`, 'error');
    }
}

/**
 * 显示设置面板
 */
function showSettingsPanel() {
    loadSettings();
    elements.settingsPanel.classList.add('visible');
}

/**
 * 隐藏设置面板
 */
function hideSettingsPanel() {
    elements.settingsPanel.classList.remove('visible');
}

/**
 * 显示日志面板
 */
function showLogPanel() {
    elements.logPanel.classList.add('visible');
    elements.logContent.scrollTop = elements.logContent.scrollHeight;
}

/**
 * 隐藏日志面板
 */
function hideLogPanel() {
    elements.logPanel.classList.remove('visible');
}

/**
 * 清空日志
 */
function clearLogs() {
    logCache.length = 0;
    renderLogs();
    addLog('日志已清空', 'info');
}

/**
 * 导出日志
 */
function saveLogs() {
    const logText = logCache.map(entry => 
        `[${entry.time}] [${entry.level.toUpperCase()}] ${entry.message}`
    ).join('\n');
    
    const blob = new Blob([logText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `lanmouse-log-${new Date().toISOString().slice(0, 10)}.txt`;
    a.click();
    URL.revokeObjectURL(url);
    
    addLog('日志已导出', 'info');
}

/**
 * 切换服务器状态
 */
async function toggleServer() {
    try {
        const status = await window.lanmouse.getServerStatus();
        
        if (status.running) {
            await window.lanmouse.stopServer();
            addLog('服务器已停止', 'info');
        } else {
            await window.lanmouse.startServer();
            addLog('服务器已启动', 'info');
        }
    } catch (err) {
        addLog(`切换服务器状态失败: ${err.message}`, 'error');
    }
}

/**
 * 刷新设备列表
 */
async function refreshDevices() {
    try {
        const status = await window.lanmouse.getServerStatus();
        updateDevicesList(status.clients || []);
        addLog('设备列表已刷新', 'info');
    } catch (err) {
        addLog(`刷新设备列表失败: ${err.message}`, 'error');
    }
}

/**
 * 初始化事件监听
 */
function initEventListeners() {
    // 服务器控制
    elements.toggleServerBtn.addEventListener('click', toggleServer);
    elements.refreshDevicesBtn.addEventListener('click', refreshDevices);
    
    // 设置面板
    elements.openSettingsBtn.addEventListener('click', showSettingsPanel);
    elements.closeSettingsBtn.addEventListener('click', hideSettingsPanel);
    elements.cancelSettingsBtn.addEventListener('click', hideSettingsPanel);
    elements.settingsForm.addEventListener('submit', (e) => {
        e.preventDefault();
        saveSettings();
    });
    
    // 日志面板
    elements.showLogsBtn.addEventListener('click', showLogPanel);
    elements.closeLogsBtn.addEventListener('click', hideLogPanel);
    elements.clearLogsBtn.addEventListener('click', clearLogs);
    elements.saveLogsBtn.addEventListener('click', saveLogs);
    
    // 点击日志面板背景关闭
    elements.logPanel.addEventListener('click', (e) => {
        if (e.target === elements.logPanel) {
            hideLogPanel();
        }
    });
    
    // ESC键关闭面板
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (elements.logPanel.classList.contains('visible')) {
                hideLogPanel();
            }
            if (elements.settingsPanel.classList.contains('visible')) {
                hideSettingsPanel();
            }
        }
    });
}

/**
 * 初始化IPC事件监听
 */
function initIPCListeners() {
    // 服务器启动事件
    window.lanmouse.onServerStarted((data) => {
        updateServerStatus(true, data.port);
        addLog(`服务器已启动，监听端口: ${data.port}`, 'info');
    });
    
    // 服务器停止事件
    window.lanmouse.onServerStopped(() => {
        updateServerStatus(false);
        updateDevicesList([]);
        addLog('服务器已停止', 'info');
    });
    
    // 服务器错误事件
    window.lanmouse.onServerError((error) => {
        addLog(`服务器错误: ${error}`, 'error');
    });
    
    // 客户端连接事件
    window.lanmouse.onClientConnected((client) => {
        addLog(`设备连接: ${client.name} (${client.ip})`, 'info');
        refreshDevices();
    });
    
    // 客户端断开事件
    window.lanmouse.onClientDisconnected((client) => {
        addLog(`设备断开: ${client.name} (${client.ip})`, 'info');
        refreshDevices();
    });
    
    // 显示设置面板事件（从托盘触发）
    window.lanmouse.onShowSettings(() => {
        showSettingsPanel();
    });
}

/**
 * 初始化应用
 */
async function initApp() {
    addLog('LanMouse 服务端初始化中...', 'info');
    
    // 获取应用版本
    try {
        const version = await window.lanmouse.getAppVersion();
        elements.appVersion.textContent = `v${version}`;
    } catch (err) {
        elements.appVersion.textContent = 'v1.0.0';
    }
    
    // 获取鼠标控制器状态
    try {
        const mouseStatus = await window.lanmouse.getMouseControllerStatus();
        elements.mouseControllerStatus.textContent = mouseStatus.running ? '就绪' : '未就绪';
    } catch (err) {
        elements.mouseControllerStatus.textContent = '未知';
    }
    
    // 获取服务器状态
    try {
        const status = await window.lanmouse.getServerStatus();
        updateServerStatus(status.running, status.port);
        updateDevicesList(status.clients || []);
    } catch (err) {
        addLog(`获取服务器状态失败: ${err.message}`, 'error');
    }
    
    // 初始化事件监听
    initEventListeners();
    initIPCListeners();
    
    addLog('初始化完成', 'info');
}

// DOM加载完成后初始化
document.addEventListener('DOMContentLoaded', initApp);
