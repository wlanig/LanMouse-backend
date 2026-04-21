/**
 * LanMouse PC服务端 - Electron 主进程
 * 处理窗口管理、系统托盘、网络服务、IPC通信
 */

const { app, BrowserWindow, Tray, Menu, nativeImage, ipcMain, dialog } = require('electron');
const path = require('path');
const log = require('electron-log');
const Store = require('electron-store');
const TCPServer = require('./tcp_server');
const { spawn, execSync } = require('child_process');

// 配置日志
log.transports.file.level = 'info';
log.transports.file.maxSize = 5 * 1024 * 1024; // 5MB
log.transports.console.level = 'debug';

// 捕获未处理的异常
process.on('uncaughtException', (error) => {
    log.error('Uncaught Exception:', error);
    app.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    log.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// 初始化配置存储
const store = new Store({
    defaults: {
        port: 19876,
        password: '',
        autoStart: false,
        startMinimized: false,
        debugMode: false
    }
});

// 全局变量
let mainWindow = null;
let tray = null;
let tcpServer = null;
let mouseController = null;
let isQuitting = false;

// 创建主窗口
function createWindow() {
    log.info('Creating main window...');

    const windowConfig = {
        width: 600,
        height: 500,
        minWidth: 500,
        minHeight: 400,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js'),
            sandbox: false
        },
        icon: getTrayIconPath(),
        show: !store.get('startMinimized'),
        frame: true,
        resizable: true
    };

    mainWindow = new BrowserWindow(windowConfig);

    // 加载HTML页面
    mainWindow.loadFile(path.join(__dirname, 'index.html'));

    // 窗口最小化时隐藏到托盘
    mainWindow.on('minimize', () => {
        if (store.get('startMinimized')) {
            mainWindow.hide();
        }
    });

    // 窗口关闭时隐藏到托盘（除非是完全退出）
    mainWindow.on('close', (event) => {
        if (!isQuitting) {
            event.preventDefault();
            mainWindow.hide();
            return false;
        }
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    // 开发模式下打开开发者工具
    if (store.get('debugMode')) {
        mainWindow.webContents.openDevTools();
    }

    log.info('Main window created successfully');
}

// 获取托盘图标路径
function getTrayIconPath() {
    const iconName = process.platform === 'win32' ? 'icon.ico' : 'icon.png';
    return path.join(__dirname, 'assets', iconName);
}

// 创建托盘图标
function createTray() {
    log.info('Creating system tray...');

    // 创建托盘图标
    let trayIcon;
    const iconPath = getTrayIconPath();
    
    try {
        trayIcon = nativeImage.createFromPath(iconPath);
        if (trayIcon.isEmpty()) {
            // 如果图标文件不存在，创建空白图标
            trayIcon = nativeImage.createEmpty();
        }
    } catch (e) {
        log.warn('Failed to load tray icon, using default');
        trayIcon = nativeImage.createEmpty();
    }

    // 调整图标大小以适应系统托盘
    if (!trayIcon.isEmpty()) {
        trayIcon = trayIcon.resize({ width: 16, height: 16 });
    }

    tray = new Tray(trayIcon);
    tray.setToolTip('LanMouse 服务端');

    // 更新托盘菜单
    updateTrayMenu();

    // 点击托盘图标显示/隐藏窗口
    tray.on('click', () => {
        if (mainWindow) {
            if (mainWindow.isVisible()) {
                mainWindow.hide();
            } else {
                mainWindow.show();
                mainWindow.focus();
            }
        }
    });

    log.info('System tray created successfully');
}

// 更新托盘菜单
function updateTrayMenu(connectedDevices = []) {
    const deviceList = connectedDevices.length > 0 
        ? connectedDevices.map(d => `${d.name} (${d.ip})`).join('\n')
        : '无连接设备';

    const contextMenu = Menu.buildFromTemplate([
        { 
            label: 'LanMouse 服务端', 
            enabled: false 
        },
        { type: 'separator' },
        { 
            label: `连接设备: ${connectedDevices.length}`, 
            submenu: connectedDevices.length > 0 
                ? connectedDevices.map((d, i) => ({
                    label: `${d.name} - ${d.ip}`,
                    enabled: false
                }))
                : [{ label: '无', enabled: false }]
        },
        { type: 'separator' },
        { 
            label: '显示主窗口', 
            click: () => {
                if (mainWindow) {
                    mainWindow.show();
                    mainWindow.focus();
                }
            }
        },
        { 
            label: '设置', 
            click: () => {
                if (mainWindow) {
                    mainWindow.show();
                    mainWindow.focus();
                    mainWindow.webContents.send('show-settings');
                }
            }
        },
        { type: 'separator' },
        { 
            label: '启动/停止服务', 
            type: 'checkbox',
            checked: tcpServer && tcpServer.isRunning(),
            click: (menuItem) => {
                if (menuItem.checked) {
                    startTCPServer();
                } else {
                    stopTCPServer();
                }
            }
        },
        { type: 'separator' },
        { 
            label: '退出', 
            click: () => {
                isQuitting = true;
                app.quit();
            }
        }
    ]);

    tray.setContextMenu(contextMenu);
}

// 启动TCP服务器
function startTCPServer() {
    if (tcpServer && tcpServer.isRunning()) {
        log.info('TCP server is already running');
        return;
    }

    const port = store.get('port');
    const password = store.get('password');

    log.info(`Starting TCP server on port ${port}...`);

    tcpServer = new TCPServer({
        port: port,
        password: password,
        mouseController: mouseController,
        onClientConnect: (client) => {
            log.info(`Client connected: ${client.id}`);
            if (mainWindow) {
                mainWindow.webContents.send('client-connected', client);
            }
            updateTrayMenu(tcpServer.getConnectedClients());
        },
        onClientDisconnect: (client) => {
            log.info(`Client disconnected: ${client.id}`);
            if (mainWindow) {
                mainWindow.webContents.send('client-disconnected', client);
            }
            updateTrayMenu(tcpServer.getConnectedClients());
        },
        onError: (error) => {
            log.error('TCP Server error:', error);
            if (mainWindow) {
                mainWindow.webContents.send('server-error', error.message);
            }
        }
    });

    tcpServer.start((success, error) => {
        if (success) {
            log.info('TCP server started successfully');
            if (mainWindow) {
                mainWindow.webContents.send('server-started', { port });
            }
        } else {
            log.error('Failed to start TCP server:', error);
            if (mainWindow) {
                mainWindow.webContents.send('server-error', error.message);
            }
        }
    });
}

// 停止TCP服务器
function stopTCPServer() {
    if (tcpServer) {
        log.info('Stopping TCP server...');
        tcpServer.stop();
        if (mainWindow) {
            mainWindow.webContents.send('server-stopped');
        }
        updateTrayMenu([]);
    }
}

// 初始化Python鼠标控制器
function initMouseController() {
    log.info('Initializing mouse controller...');

    const controllerPath = app.isPackaged 
        ? path.join(process.resourcesPath, 'mouse_controller.py')
        : path.join(__dirname, 'mouse_controller.py');

    mouseController = {
        process: null,
        
        start() {
            return new Promise((resolve, reject) => {
                try {
                    const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
                    
                    this.process = spawn(pythonCmd, [controllerPath], {
                        stdio: ['pipe', 'pipe', 'pipe'],
                        detached: false
                    });

                    this.process.stdout.on('data', (data) => {
                        log.debug('Mouse controller output:', data.toString().trim());
                    });

                    this.process.stderr.on('data', (data) => {
                        log.error('Mouse controller error:', data.toString().trim());
                    });

                    this.process.on('error', (err) => {
                        log.error('Failed to start mouse controller:', err);
                        reject(err);
                    });

                    this.process.on('exit', (code) => {
                        log.info(`Mouse controller exited with code ${code}`);
                        this.process = null;
                    });

                    // 等待进程启动
                    setTimeout(() => {
                        resolve();
                    }, 500);

                } catch (err) {
                    log.error('Error starting mouse controller:', err);
                    reject(err);
                }
            });
        },

        moveMouse(x, y) {
            if (this.process && this.process.stdin) {
                const cmd = `move:${x},${y}\n`;
                this.process.stdin.write(cmd);
            }
        },

        click(button = 'left') {
            if (this.process && this.process.stdin) {
                const cmd = `click:${button}\n`;
                this.process.stdin.write(cmd);
            }
        },

        scroll(amount) {
            if (this.process && this.process.stdin) {
                const cmd = `scroll:${amount}\n`;
                this.process.stdin.write(cmd);
            }
        },

        drag(startX, startY, endX, endY) {
            if (this.process && this.process.stdin) {
                const cmd = `drag:${startX},${startY},${endX},${endY}\n`;
                this.process.stdin.write(cmd);
            }
        },

        stop() {
            if (this.process) {
                this.process.kill();
                this.process = null;
            }
        }
    };

    mouseController.start().then(() => {
        log.info('Mouse controller initialized successfully');
    }).catch((err) => {
        log.warn('Failed to initialize mouse controller, using fallback:', err.message);
    });
}

// 设置开机自启动
function setAutoLaunch(enable) {
    log.info(`Setting auto launch: ${enable}`);
    
    if (process.platform === 'win32') {
        app.setLoginItemSettings({
            openAtLogin: enable,
            path: app.getPath('exe')
        });
    } else if (process.platform === 'darwin') {
        app.setLoginItemSettings({
            openAtLogin: enable
        });
    }
    
    store.set('autoStart', enable);
}

// 注册IPC处理器
function registerIPCHandlers() {
    log.info('Registering IPC handlers...');

    // 获取设置
    ipcMain.handle('get-settings', () => {
        return {
            port: store.get('port'),
            password: store.get('password'),
            autoStart: store.get('autoStart'),
            startMinimized: store.get('startMinimized'),
            debugMode: store.get('debugMode')
        };
    });

    // 保存设置
    ipcMain.handle('save-settings', (event, settings) => {
        log.info('Saving settings:', settings);
        
        const oldPort = store.get('port');
        const oldPassword = store.get('password');
        
        store.set('port', settings.port);
        store.set('password', settings.password);
        store.set('autoStart', settings.autoStart);
        store.set('startMinimized', settings.startMinimized);
        store.set('debugMode', settings.debugMode);

        // 设置开机自启动
        setAutoLaunch(settings.autoStart);

        // 如果端口或密码改变，重启服务器
        if (tcpServer && tcpServer.isRunning()) {
            if (oldPort !== settings.port || oldPassword !== settings.password) {
                stopTCPServer();
                startTCPServer();
            }
        }

        return { success: true };
    });

    // 获取服务器状态
    ipcMain.handle('get-server-status', () => {
        return {
            running: tcpServer ? tcpServer.isRunning() : false,
            port: store.get('port'),
            clients: tcpServer ? tcpServer.getConnectedClients() : []
        };
    });

    // 启动服务器
    ipcMain.handle('start-server', () => {
        startTCPServer();
        return { success: true };
    });

    // 停止服务器
    ipcMain.handle('stop-server', () => {
        stopTCPServer();
        return { success: true };
    });

    // 获取屏幕分辨率
    ipcMain.handle('get-screen-size', () => {
        const { screen } = require('electron');
        const primaryDisplay = screen.getPrimaryDisplay();
        return {
            width: primaryDisplay.workAreaSize.width,
            height: primaryDisplay.workAreaSize.height,
            scaleFactor: primaryDisplay.scaleFactor
        };
    });

    // 获取鼠标控制器状态
    ipcMain.handle('get-mouse-controller-status', () => {
        return {
            running: mouseController && mouseController.process !== null
        };
    });

    // 获取应用版本
    ipcMain.handle('get-app-version', () => {
        return app.getVersion();
    });

    log.info('IPC handlers registered successfully');
}

// 应用准备就绪
app.whenReady().then(() => {
    log.info('App is ready, initializing...');

    // 创建窗口
    createWindow();

    // 创建托盘
    createTray();

    // 注册IPC处理器
    registerIPCHandlers();

    // 初始化鼠标控制器
    initMouseController();

    // 自动启动TCP服务器
    startTCPServer();

    // macOS: 点击Dock图标时显示窗口
    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        } else if (mainWindow) {
            mainWindow.show();
        }
    });

    log.info('Initialization complete');
});

// 所有窗口关闭
app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        // 不退出应用，保持托盘运行
    }
});

// 应用退出前
app.on('before-quit', () => {
    log.info('App is quitting...');
    isQuitting = true;

    // 停止TCP服务器
    if (tcpServer) {
        tcpServer.stop();
    }

    // 停止鼠标控制器
    if (mouseController) {
        mouseController.stop();
    }
});

// 应用退出
app.on('quit', () => {
    log.info('App quit');
});
