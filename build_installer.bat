@echo off
echo 正在准备 LemonTV Windows 安装包...

REM 检查是否已构建发布版本
if not exist "build\windows\x64\runner\Release\LemonTV.exe" (
    echo 构建发布版本不存在，正在构建...
    flutter build windows --release
    if errorlevel 1 (
        echo 构建失败！
        pause
        exit /b 1
    )
)

REM 创建安装包目录
if not exist "installer" mkdir installer

REM 检查是否安装了 Inno Setup
where /q ISCC
if errorlevel 1 (
    echo 未找到 Inno Setup 编译器 (ISCC)
    echo 请先安装 Inno Setup:
    echo 1. 下载并安装 Inno Setup: http://www.jrsoftware.org/isdl.php
    echo 2. 然后重新运行此脚本
    echo.
    echo 或者，您可以使用下面的便携式版本方法:
    echo - 复制 build\windows\x64\runner\Release 目录下的所有文件
    echo - 到一个新文件夹中，如 "LemonTV_Portable"
    echo - 这样就可以直接运行 LemonTV.exe
    pause
    exit /b 1
)

echo 正在使用 Inno Setup 创建安装包...
ISCC "windows_installer.iss"

if errorlevel 1 (
    echo 安装包创建失败！
    pause
    exit /b 1
)

echo.
echo 安装包已创建完成！
echo 查找位置: installer\ 目录下的 LemonTV_Setup.exe
echo.
pause