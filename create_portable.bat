@echo off
echo 正在创建 LemonTV 便携版本...

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

REM 创建便携版本目录
set PORTABLE_DIR=LemonTV_Portable
if exist "%PORTABLE_DIR%" rmdir /s /q "%PORTABLE_DIR%"
mkdir "%PORTABLE_DIR%"

echo 复制文件到便携版本目录...
xcopy "build\windows\x64\runner\Release\*" "%PORTABLE_DIR%" /E /I /Y

REM 复制许可证和说明文件
if exist "LICENSE" copy "LICENSE" "%PORTABLE_DIR%" /Y
if exist "README.md" copy "README.md" "%PORTABLE_DIR%" /Y

echo.
echo 便携版本已创建完成！
echo 文件位置: %PORTABLE_DIR% 目录
echo.
echo 您可以直接运行 %PORTABLE_DIR%\LemonTV.exe 来启动程序
echo.
pause