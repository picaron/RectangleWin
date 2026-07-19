@echo off

REM Generate Windows version info (res_windows.go)
echo {} > temp.json
go run github.com/josephspurrier/goversioninfo/cmd/goversioninfo@latest -64 -icon assets/icon.ico temp.json
del temp.json

REM Build the Windows binary (GUI mode, no console window)
set GOOS=windows
go build -ldflags -H=windowsgui .