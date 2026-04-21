#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LanMouse PC服务端 - Python鼠标控制器
通过标准输入接收指令，控制鼠标移动、点击、滚动等操作

支持平台: Windows, macOS, Linux
依赖: pyautogui (跨平台)

Windows平台也可使用ctypes直接调用user32.dll（无依赖）
"""

import sys
import os
import time
import platform

# 检测平台
SYSTEM = platform.system()

def get_mouse_controller():
    """根据系统平台返回合适的鼠标控制器"""
    if SYSTEM == 'Windows':
        return WindowsMouseController()
    elif SYSTEM == 'Darwin':
        return MacMouseController()
    else:
        return LinuxMouseController()

class MouseController:
    """鼠标控制器基类"""
    
    def move_to(self, x, y):
        """移动鼠标到绝对坐标"""
        raise NotImplementedError
    
    def move_relative(self, dx, dy):
        """相对移动鼠标"""
        raise NotImplementedError
    
    def click(self, button='left'):
        """点击鼠标按钮"""
        raise NotImplementedError
    
    def double_click(self, button='left'):
        """双击鼠标按钮"""
        raise NotImplementedError
    
    def scroll(self, amount):
        """滚动鼠标滚轮"""
        raise NotImplementedError
    
    def drag(self, start_x, start_y, end_x, end_y):
        """拖拽操作"""
        raise NotImplementedError
    
    def press(self, button='left'):
        """按下鼠标按钮"""
        raise NotImplementedError
    
    def release(self, button='left'):
        """释放鼠标按钮"""
        raise NotImplementedError


class WindowsMouseController(MouseController):
    """
    Windows平台鼠标控制器
    使用ctypes调用user32.dll实现
    """
    
    def __init__(self):
        try:
            import ctypes
            self.ctypes = ctypes
            self.user32 = ctypes.windll.user32
            
            # 获取屏幕尺寸
            self.screen_width = self.user32.GetSystemMetrics(0)
            self.screen_height = self.user32.GetSystemMetrics(1)
            
            # 定义结构体
            class POINT(ctypes.Structure):
                _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]
            
            self.POINT = POINT
            
            # 鼠标事件常量
            self.MOUSEEVENTF_LEFTDOWN = 0x0002
            self.MOUSEEVENTF_LEFTUP = 0x0004
            self.MOUSEEVENTF_RIGHTDOWN = 0x0008
            self.MOUSEEVENTF_RIGHTUP = 0x0010
            self.MOUSEEVENTF_MIDDLEDOWN = 0x0020
            self.MOUSEEVENTF_MIDDLEUP = 0x0040
            self.MOUSEEVENTF_WHEEL = 0x0800
            self.MOUSEEVENTF_MOVE = 0x0001
            self.MOUSEEVENTF_ABSOLUTE = 0x8000
            
            self.use_pyautogui = False
            print(f"Windows controller initialized (native), screen: {self.screen_width}x{self.screen_height}")
        except Exception as e:
            print(f"Failed to initialize native Windows controller: {e}")
            print("Falling back to pyautogui...")
            self.use_pyautogui = True
            import pyautogui
            self.pyautogui = pyautogui
            self.screen_width, self.screen_height = pyautogui.size()
    
    def move_to(self, x, y):
        """移动鼠标到绝对坐标"""
        if self.use_pyautogui:
            self.pyautogui.moveTo(x, y)
        else:
            # 将坐标转换为 normalized coordinates (0-65535)
            nx = int((x / self.screen_width) * 65535)
            ny = int((y / self.screen_height) * 65535)
            self.user32.mouse_event(self.MOUSEEVENTF_MOVE | self.MOUSEEVENTF_ABSOLUTE, nx, ny, 0, 0)
    
    def move_relative(self, dx, dy):
        """相对移动鼠标"""
        if self.use_pyautogui:
            self.pyautogui.move(dx, dy)
        else:
            self.user32.mouse_event(self.MOUSEEVENTF_MOVE, dx, dy, 0, 0)
    
    def click(self, button='left'):
        """点击鼠标按钮"""
        if self.use_pyautogui:
            self.pyautogui.click(button=button)
        else:
            if button == 'left':
                self.user32.mouse_event(self.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
                time.sleep(0.05)
                self.user32.mouse_event(self.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
            elif button == 'right':
                self.user32.mouse_event(self.MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
                time.sleep(0.05)
                self.user32.mouse_event(self.MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0)
            elif button == 'middle':
                self.user32.mouse_event(self.MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0)
                time.sleep(0.05)
                self.user32.mouse_event(self.MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0)
    
    def double_click(self, button='left'):
        """双击鼠标按钮"""
        self.click(button)
        time.sleep(0.1)
        self.click(button)
    
    def scroll(self, amount):
        """滚动鼠标滚轮"""
        if self.use_pyautogui:
            self.pyautogui.scroll(amount)
        else:
            # amount: 滚动量，通常为120表示滚动1行
            self.user32.mouse_event(self.MOUSEEVENTF_WHEEL, 0, 0, amount * 120 // 100, 0)
    
    def drag(self, start_x, start_y, end_x, end_y):
        """拖拽操作"""
        if self.use_pyautogui:
            self.pyautogui.moveTo(start_x, start_y)
            self.pyautogui.mouseDown()
            time.sleep(0.05)
            self.pyautogui.moveTo(end_x, end_y, duration=0.2)
            self.pyautogui.mouseUp()
        else:
            # 移动到起始位置
            self.move_to(start_x, start_y)
            time.sleep(0.05)
            # 按下鼠标
            self.user32.mouse_event(self.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
            time.sleep(0.05)
            # 移动到目标位置
            self.move_to(end_x, end_y)
            time.sleep(0.1)
            # 释放鼠标
            self.user32.mouse_event(self.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    
    def press(self, button='left'):
        """按下鼠标按钮"""
        if self.use_pyautogui:
            self.pyautogui.mouseDown(button=button)
        else:
            if button == 'left':
                self.user32.mouse_event(self.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
            elif button == 'right':
                self.user32.mouse_event(self.MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0)
            elif button == 'middle':
                self.user32.mouse_event(self.MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, 0)
    
    def release(self, button='left'):
        """释放鼠标按钮"""
        if self.use_pyautogui:
            self.pyautogui.mouseUp(button=button)
        else:
            if button == 'left':
                self.user32.mouse_event(self.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
            elif button == 'right':
                self.user32.mouse_event(self.MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0)
            elif button == 'middle':
                self.user32.mouse_event(self.MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0)


class MacMouseController(MouseController):
    """
    macOS平台鼠标控制器
    使用ctypes调用CoreGraphics实现
    """
    
    def __init__(self):
        try:
            import ctypes
            import ctypes.util
            
            self.ctypes = ctypes
            self.coregraphics = ctypes.CDLL(ctypes.util.find_library('CoreGraphics'))
            
            # 获取屏幕尺寸
            self.screen_width = int(self.coregraphics.CGDisplayPixelsWide(0))
            self.screen_height = int(self.coregraphics.CGDisplayPixelsHigh(0))
            
            # 定义CGPoint
            class CGPoint(ctypes.Structure):
                _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]
            
            self.CGPoint = CGPoint
            self.use_pyautogui = False
            print(f"Mac controller initialized (native), screen: {self.screen_width}x{self.screen_height}")
        except Exception as e:
            print(f"Failed to initialize native Mac controller: {e}")
            print("Falling back to pyautogui...")
            self.use_pyautogui = True
            import pyautogui
            self.pyautogui = pyautogui
            self.screen_width, self.screen_height = pyautogui.size()
    
    def move_to(self, x, y):
        """移动鼠标到绝对坐标"""
        if self.use_pyautogui:
            self.pyautogui.moveTo(x, y)
        else:
            point = self.CGPoint(x, y)
            self.coregraphics.CGDisplayMoveCursorToPoint(0, point)
    
    def move_relative(self, dx, dy):
        """相对移动鼠标"""
        if self.use_pyautogui:
            self.pyautogui.move(dx, dy)
        else:
            current = self.coregraphics.CGEventGetLocation(
                self.coregraphics.CGEventCreate(None)
            )
            point = self.CGPoint(current.x + dx, current.y + dy)
            self.coregraphics.CGDisplayMoveCursorToPoint(0, point)
    
    def _click(self, button, down=True):
        """内部方法：发送鼠标事件"""
        if self.use_pyautogui:
            if down:
                self.pyautogui.mouseDown(button=button)
            else:
                self.pyautogui.mouseUp(button=button)
        else:
            # 0 = left, 1 = right, 2 = middle
            button_map = {'left': 0, 'right': 1, 'middle': 2}
            btn = button_map.get(button, 0)
            
            event_type_down = [6, 7, 8]  # kCGEventLeftMouseDown, etc.
            event_type_up = [9, 10, 11]   # kCGEventLeftMouseUp, etc.
            
            point = self.coregraphics.CGEventGetLocation(
                self.coregraphics.CGEventCreate(None)
            )
            
            down_type = 6 + btn * 2 if btn == 0 else 6 + btn * 2 + 4
            up_type = 7 + btn * 2 if btn == 0 else 7 + btn * 2 + 4
            
            event = self.coregraphics.CGEventCreateMouseEvent(
                None,
                down_type if down else up_type,
                point,
                btn
            )
            self.coregraphics.CGEventPost(0, event)
    
    def click(self, button='left'):
        """点击鼠标按钮"""
        self._click(button, True)
        time.sleep(0.05)
        self._click(button, False)
    
    def double_click(self, button='left'):
        """双击鼠标按钮"""
        self.click(button)
        time.sleep(0.1)
        self.click(button)
    
    def scroll(self, amount):
        """滚动鼠标滚轮"""
        if self.use_pyautogui:
            self.pyautogui.scroll(amount)
        else:
            # 水平滚动和垂直滚动
            scroll_amount = int(amount * 120 // 100)
            point = self.coregraphics.CGEventGetLocation(
                self.coregraphics.CGEventCreate(None)
            )
            event = self.coregraphics.CGEventCreateScrollWheelEvent(
                None, 0, 1, scroll_amount
            )
            self.coregraphics.CGEventPost(0, event)
    
    def drag(self, start_x, start_y, end_x, end_y):
        """拖拽操作"""
        if self.use_pyautogui:
            self.pyautogui.moveTo(start_x, start_y)
            self.pyautogui.mouseDown()
            time.sleep(0.05)
            self.pyautogui.moveTo(end_x, end_y, duration=0.2)
            self.pyautogui.mouseUp()
        else:
            self.move_to(start_x, start_y)
            time.sleep(0.05)
            self._click('left', True)
            time.sleep(0.05)
            self.move_to(end_x, end_y)
            time.sleep(0.1)
            self._click('left', False)


class LinuxMouseController(MouseController):
    """
    Linux平台鼠标控制器
    使用pyautogui或xdotool实现
    """
    
    def __init__(self):
        try:
            import pyautogui
            self.pyautogui = pyautogui
            self.screen_width, self.screen_height = pyautogui.size()
            self.use_xdotool = False
            print(f"Linux controller initialized (pyautogui), screen: {self.screen_width}x{self.screen_height}")
        except ImportError:
            print("pyautogui not available, trying xdotool...")
            self.use_xdotool = True
            self.screen_width = 1920  # 默认值
            self.screen_height = 1080
    
    def move_to(self, x, y):
        """移动鼠标到绝对坐标"""
        if self.use_xdotool:
            os.system(f'xdotool mousemove {int(x)} {int(y)}')
        else:
            self.pyautogui.moveTo(x, y)
    
    def move_relative(self, dx, dy):
        """相对移动鼠标"""
        if self.use_xdotool:
            os.system(f'xdotool mousemove_relative -- {int(dx)} {int(dy)}')
        else:
            self.pyautogui.move(dx, dy)
    
    def click(self, button='left'):
        """点击鼠标按钮"""
        if self.use_xdotool:
            os.system(f'xdotool click 1' if button == 'left' else 
                     f'xdotool click 3' if button == 'right' else 
                     f'xdotool click 2')
        else:
            self.pyautogui.click(button=button)
    
    def double_click(self, button='left'):
        """双击鼠标按钮"""
        if self.use_xdotool:
            os.system(f'xdotool click --repeat 2 1' if button == 'left' else 
                     f'xdotool click --repeat 2 3' if button == 'right' else 
                     f'xdotool click --repeat 2 2')
        else:
            self.pyautogui.doubleClick(button=button)
    
    def scroll(self, amount):
        """滚动鼠标滚轮"""
        if self.use_xdotool:
            clicks = '4' if amount > 0 else '5'
            count = abs(amount)
            os.system(f'xdotool click --repeat {count} {clicks}')
        else:
            self.pyautogui.scroll(amount)
    
    def drag(self, start_x, start_y, end_x, end_y):
        """拖拽操作"""
        if self.use_xdotool:
            os.system(f'xdotool mousemove {int(start_x)} {int(start_y)}')
            os.system('xdotool mousedown 1')
            os.system(f'xdotool mousemove {int(end_x)} {int(end_y)}')
            os.system('xdotool mouseup 1')
        else:
            self.pyautogui.moveTo(start_x, start_y)
            self.pyautogui.mouseDown()
            time.sleep(0.05)
            self.pyautogui.moveTo(end_x, end_y, duration=0.2)
            self.pyautogui.mouseUp()


def main():
    """主循环：读取stdin，处理命令"""
    controller = get_mouse_controller()
    
    print("Mouse controller ready", flush=True)
    
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            
            line = line.strip()
            if not line:
                continue
            
            # 解析命令
            if ':' in line:
                cmd, params = line.split(':', 1)
            else:
                cmd = line
                params = ''
            
            cmd = cmd.strip().lower()
            
            try:
                if cmd == 'move':
                    x, y = map(float, params.split(','))
                    # 检测是否使用相对移动（当值较小时）
                    if abs(x) < 1000 and abs(y) < 1000:
                        if abs(x) <= 100 and abs(y) <= 100:
                            # 可能是相对坐标
                            controller.move_relative(int(x), int(y))
                        else:
                            # 绝对坐标
                            controller.move_to(int(x), int(y))
                    else:
                        controller.move_to(int(x), int(y))
                
                elif cmd == 'click':
                    button = params.strip() or 'left'
                    controller.click(button)
                
                elif cmd == 'double_click':
                    button = params.strip() or 'left'
                    controller.double_click(button)
                
                elif cmd == 'scroll':
                    amount = float(params)
                    controller.scroll(int(amount))
                
                elif cmd == 'drag':
                    start_x, start_y, end_x, end_y = map(float, params.split(','))
                    controller.drag(int(start_x), int(start_y), int(end_x), int(end_y))
                
                elif cmd == 'press':
                    button = params.strip() or 'left'
                    controller.press(button)
                
                elif cmd == 'release':
                    button = params.strip() or 'left'
                    controller.release(button)
                
                elif cmd == 'quit' or cmd == 'exit':
                    print("Exiting mouse controller", flush=True)
                    break
                
                else:
                    print(f"Unknown command: {cmd}", flush=True)
            
            except Exception as e:
                print(f"Error executing '{line}': {e}", flush=True)
        
        except KeyboardInterrupt:
            print("\nInterrupted, exiting...", flush=True)
            break
        except Exception as e:
            print(f"Error: {e}", flush=True)

if __name__ == '__main__':
    main()
