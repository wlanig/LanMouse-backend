; Custom NSIS script to delete AppData on uninstall
; electron-builder calls customUnInstall macro during uninstall

!macro customUnInstall
  ; Remove electron-store and electron-log data directories
  RMDir /r "$APPDATA\lanmouse-pc-server"
  RMDir /r "$APPDATA\com.lanmouse"
!macroend
