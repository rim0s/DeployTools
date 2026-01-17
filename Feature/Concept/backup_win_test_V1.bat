@echo off
chcp 65001 >nul

:: 定义源目录或文件和目标目录
set "SOURCE=C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
set "DESTINATION=E:\bctest"
set "TEMP_BACKUP=F:\"
set "TEMP_BACKUP_VOLUME=%TEMP_BACKUP:~0,2%"

REM 检查当前命令提示符是否以管理员权限运行
reg query HKU\S-1-5-19 1>nul 2>nul

REM 如果结果不为0，说明不是以管理员权限运行
if %errorlevel% NEQ 0 (
    echo Administrator rights are required to run this script...
    goto UACPrompt
) else ( goto gotAdmin )

REM 获取管理员权限
:UACPrompt
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit

REM 已经获取管理员权限
:gotAdmin
pushd "%CD%"
CD /D "%~dp0"

goto START

:START

:: 检查目标目录是否存在，如果不存在则创建
if not exist "%DESTINATION%" (
    mkdir "%DESTINATION%"
)

:: 检查文件是否被占用
echo 正在检查文件是否被占用...
for %%F in ("%SOURCE%\*") do (
    >nul 2>nul (>>"%%F" echo.) && (
        echo 文件 %%F 未被占用。
    ) || (
        echo 文件 %%F 被占用，检测系统是否支持卷影复制...
        goto :VSS_CHECK
    )
)

:: 如果文件未被占用，直接使用 robocopy 进行备份
echo 文件未被占用，直接执行备份操作...
robocopy "%SOURCE%" "%DESTINATION%" /MIR /R:3 /W:5
if %ERRORLEVEL% GEQ 8 (
    echo 文件备份失败，请检查日志。
    goto :EOF
) else (
    echo 文件备份成功！
    goto :EOF
)

:VSS_CHECK
set "MAX_RETRIES=5"
set "RETRY_COUNT=0"

:: 检查卷影复制服务是否正在运行
sc query vss | find "RUNNING" >nul
if %ERRORLEVEL% NEQ 0 (
    set /a RETRY_COUNT+=1
    if %RETRY_COUNT% GEQ %MAX_RETRIES% (
        echo 卷影复制服务启动失败，请检查系统配置。
        pause
        exit /b
    )
    echo 等待卷影复制服务启动中，重试第 %RETRY_COUNT% 次...
    ping 127.0.1 -n 5 >nul
    goto :CHECK_VSS_STATUS
)
echo 卷影复制服务已成功启动。

::测试环境先清理一下
wbadmin delete backup -keepVersions:0 -quiet

:: 检查磁盘文件系统是否为 NTFS
for %%I in (C:) do (
    wmic logicaldisk where "DeviceID='%%I'" get FileSystem | find "NTFS" >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo 磁盘 %%I 不是 NTFS 文件系统，无法启用卷影复制。
        pause
        exit /b
    )
)

:: 验证卷影复制配置
@REM vssadmin list shadowstorage


:: 提取源目录所在的卷(例如 C:)
for %%I in ("%SOURCE%") do set "SOURCE_VOLUME=%%~dI"

:: 使用 PowerShell 获取源卷的大小和已用空间(以 GB 为单位，取整数部分)
for /f %%I in ('powershell -Command "[math]::Floor((Get-PSDrive -Name %SOURCE_VOLUME:~0,1%).Used / 1GB)"') do set "SOURCE_USED_GB=%%I"
for /f %%I in ('powershell -Command "[math]::Floor((Get-PSDrive -Name %SOURCE_VOLUME:~0,1%).Free / 1GB)"') do set "SOURCE_FREE_GB=%%I"

:: 检查变量是否为空
if "%SOURCE_USED_GB%"=="" (
    echo 无法获取源卷的已用空间，请检查 PowerShell 命令是否正确。
    goto :EOF
)
if "%SOURCE_FREE_GB%"=="" (
    echo 无法获取源卷的可用空间，请检查 PowerShell 命令是否正确。
    goto :EOF
)

:: 计算源卷的总大小(以 GB 为单位)
set /a SOURCE_SIZE_GB=%SOURCE_USED_GB% + %SOURCE_FREE_GB%

:: 计算目标分区的最低需求空间(源卷已用空间 + 20% 冗余)
set /a REQUIRED_SPACE_GB=%SOURCE_USED_GB% + (%SOURCE_USED_GB% / 5)

:: 使用 PowerShell 获取卷影备份临时存放的目标分区的可用空间(以 GB 为单位，取整数部分)
for /f %%I in ('powershell -Command "[math]::Floor((Get-PSDrive -Name %TEMP_BACKUP:~0,1%).Free / 1GB)"') do set "FREE_SPACE_GB=%%I"

:: 检查变量是否为空
if "%FREE_SPACE_GB%"=="" (
    echo 无法获取卷影备份临时存放分区的可用空间，请检查 PowerShell 命令是否正确。
    goto :EOF
)

:: 检查卷影备份临时存放分区是否满足需求
if %FREE_SPACE_GB% LSS %REQUIRED_SPACE_GB% (
    echo 卷影备份临时存放分区的可用空间不足。
    echo 源卷已用空间为 %SOURCE_USED_GB% GB，卷影备份临时存放分区至少需要 %REQUIRED_SPACE_GB% GB。
    echo 请更换更大的目标分区以存放卷影备份临时文件,并且将脚本顶部TEMP_BACKUP设置为该分区编号。
    goto :EOF
)

echo 卷影备份临时存放分区的可用空间为 %FREE_SPACE_GB% GB，满足备份需求，继续执行备份操作...

:: 使用卷影复制进行备份
echo 系统支持卷影复制，正在创建卷影快照...

::goto :FIND_VHDFILE
:: 定义临时文件存储 SHADOW_ID 列表
set "SHADOW_ID_BEFORE=shadow_before.txt"
set "SHADOW_ID_AFTER=shadow_after.txt"
set "NEW_SHADOW_ID=new_shadow_id.txt"

:: 清理临时文件
if exist %SHADOW_ID_BEFORE% del /f /q %SHADOW_ID_BEFORE%
if exist %SHADOW_ID_AFTER% del /f /q %SHADOW_ID_AFTER%
if exist %NEW_SHADOW_ID% del /f /q %NEW_SHADOW_ID%

:: 获取当前系统的所有 SHADOW_ID(脚本开始时)
echo 正在获取现有的卷影快照 ID...
vssadmin list shadows | findstr /i "Shadow Copy ID" > %SHADOW_ID_BEFORE%
if %ERRORLEVEL% NEQ 0 (
    echo 无法获取现有的卷影快照 ID，请检查系统配置。
    @REM goto :EOF
)

goto :TEST_POINT_1

:: 使用 wbadmin 创建卷影备份
echo 正在使用 wbadmin 创建卷影备份...
wbadmin start backup -backupTarget:%TEMP_BACKUP_VOLUME% -include:%SOURCE_VOLUME% -quiet > wbadmin_output.log 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo wbadmin 备份失败，请检查系统配置。
    echo 以下是 wbadmin 的错误信息:
    type wbadmin_output.log
    goto :EOF
)

:TEST_POINT_1

:: 获取新的 SHADOW_ID 列表(wbadmin 创建快照后)
echo 正在获取新的卷影快照 ID...
vssadmin list shadows | findstr /i "Shadow Copy ID" > %SHADOW_ID_AFTER%

:: 比较两次的 SHADOW_ID 列表，找出新增的 ID
echo 正在比较卷影快照 ID 列表，确定新增的快照...
for /f "delims=" %%I in ('findstr /v /g:%SHADOW_ID_BEFORE% %SHADOW_ID_AFTER%') do echo %%I >> %NEW_SHADOW_ID%
if %ERRORLEVEL% NEQ 0 (
    echo 无法比较卷影快照 ID 列表，请检查系统配置。
    @REM goto :EOF
)

:FIND_VHDFILE
:: 动态查找 WindowsImageBackup 目录
echo 正在查找 WindowsImageBackup 目录...
for /f "tokens=*" %%I in ('dir "%TEMP_BACKUP%" /s /b /ad ^| findstr /i "WindowsImageBackup"') do (
    set "BACKUP_DIR=%%I"
    goto :FOUND_BACKUP_DIR
)
if "%BACKUP_DIR%"=="" (
    echo 未找到 WindowsImageBackup 目录，请检查备份路径。
    goto :EOF
)

:FOUND_BACKUP_DIR
echo 找到的 WindowsImageBackup 目录为:%BACKUP_DIR%

:: 查找最新的 VHDX 文件
echo 正在查找最新的备份 VHDX 文件...
set "VHD_FILE="
for /f "delims=" %%I in ('dir "%BACKUP_DIR%\*.vhdx" /s /b /o-d 2^>nul') do (
    set "VHD_FILE=%%I"
    goto :FOUND_VHD
)
if "%VHD_FILE%"=="" (
    echo 未找到备份的 VHDX 文件，请检查 wbadmin 是否正确生成备份。
    goto :EOF
)

:FOUND_VHD
echo 找到的 VHDX 文件为:%VHD_FILE%

:: 挂载备份的 VHD 文件
echo 正在挂载备份的 VHD 文件...
echo select vdisk file="%VHD_FILE%" > mount_vhd.txt
echo attach vdisk >> mount_vhd.txt
diskpart /s mount_vhd.txt 
if %ERRORLEVEL% NEQ 0 (
    echo 无法挂载 VHD 文件，请检查系统配置。
    goto :EOF
)

:: 获取虚拟磁盘的磁盘编号
echo 正在获取虚拟磁盘的磁盘编号...
echo list disk > check_disk.txt
diskpart /s check_disk.txt > disk_output.txt
set "DISK_NUMBER="
for /f "tokens=2 delims= " %%I in ('findstr /i "磁盘" disk_output.txt ^| findstr /i "联机"') do (
    set "DISK_NUMBER=%%I"
)
if "%DISK_NUMBER%"=="" (
    echo 无法找到虚拟磁盘，请检查磁盘状态。
    type disk_output.txt
    goto :EOF
)

echo 找到的虚拟磁盘编号为:%DISK_NUMBER%
:: ##############  此处已经找到磁盘编号 DISK_NUMBER ###############

goto :TEST_POINT_2

:: 使用 wmic 获取分区编号
echo 正在获取分区编号...
for /f "skip=1 tokens=1 delims= " %%I in ('wmic partition where "DiskIndex=%DISK_NUMBER%" get Index') do (
    set "PARTITION_NUMBER=%%I"
    goto :CHECK_PARTITION_NUMBER
)

:CHECK_PARTITION_NUMBER
if "%PARTITION_NUMBER%"=="" (
    echo 无法获取分区编号，请检查虚拟磁盘状态。
    goto :EOF
)
echo 找到的分区编号为:%PARTITION_NUMBER%

:: 调整分区编号以匹配 diskpart
set /a DISKPART_PARTITION_NUMBER=%PARTITION_NUMBER% + 1
echo 调整后的分区编号为:%DISKPART_PARTITION_NUMBER%

:: 使用 wmic 获取分区大小
echo 正在获取分区大小...
for /f "skip=1 tokens=1 delims= " %%I in ('wmic partition where "DiskIndex=%DISK_NUMBER%" get Size') do (
    set "PARTITION_SIZE=%%I"
    goto :CHECK_PARTITION_SIZE
)

:CHECK_PARTITION_SIZE
if "%PARTITION_SIZE%"=="" (
    echo 无法获取分区大小，请检查虚拟磁盘状态。
    goto :EOF
)
echo 找到的分区大小为:%PARTITION_SIZE% 字节

:: 检查分区大小是否有效
if %PARTITION_SIZE% LEQ 0 (
    echo 找到的分区大小无效，请检查虚拟磁盘状态。
    goto :EOF
)

:: 输出解析结果
echo wmic分区编号:%PARTITION_NUMBER%，大小:%PARTITION_SIZE% 字节。
echo diskpart分区编号:%DISKPART_PARTITION_NUMBER%，大小:%PARTITION_SIZE% 字节。

:TEST_POINT_2
:: 列出磁盘的分区信息
echo list disk > check_disk.txt
echo select disk %DISK_NUMBER% >> check_disk.txt
echo list partition >> check_disk.txt
diskpart /s check_disk.txt > partition_list.txt

:: 根据分区大小匹配目标分区编号(选择最大的分区)
set "TARGET_PARTITION_NUMBER="
set "MAX_PARTITION_SIZE=0"

:: 调用 PowerShell 脚本获取最大的分区编号
for /f "delims=" %%P in ('powershell -NoProfile -Command ^
    "Get-Partition | Where-Object { $_.DiskNumber -eq %DISK_NUMBER% } | Sort-Object -Property Size -Descending | Select-Object -First 1 | ForEach-Object { $_.PartitionNumber }"') do (
    set "TARGET_PARTITION_NUMBER=%%P"
)

:: 检查是否找到目标分区编号
if "%TARGET_PARTITION_NUMBER%"=="" (
    echo 无法找到目标分区，请检查分区信息。
    goto :EOF
)

echo 找到的目标分区编号为:%TARGET_PARTITION_NUMBER%
::##############  此处已经找到分区编号 PARTITION_NUMBER ###############

:: 使用找到的分区编号分配盘符
echo select disk %DISK_NUMBER% > assign_partition.txt
echo select partition %TARGET_PARTITION_NUMBER% >> assign_partition.txt
echo assign >> assign_partition.txt
diskpart /s assign_partition.txt > diskpart_output.txt

:: 检查分配盘符是否成功
findstr /i "成功" diskpart_output.txt >nul
if %ERRORLEVEL% NEQ 0 (
    echo 无法为分区分配盘符，请检查日志。
    type diskpart_output.txt
    goto :EOF
)

echo 分区已成功分配盘符。

:: 获取分配的盘符
for /f "tokens=2 delims==" %%I in ('wmic logicaldisk where "DeviceID like '%%'" get DeviceID /value') do (
    set "MOUNTED_DRIVE=%%I"
)

if "%MOUNTED_DRIVE%"=="" (
    echo 无法找到分配的盘符，请检查卷状态。
    goto :EOF
)

echo 分区已成功加载为卷，盘符为:%MOUNTED_DRIVE%

:: 提取相对路径
set "RELATIVE_SOURCE=%SOURCE:~3%"

:: 验证挂载的虚拟磁盘目录结构
echo 挂载的虚拟磁盘目录结构:
dir %MOUNTED_DRIVE%\

:: 使用 robocopy 复制文件
echo 正在从挂载的虚拟磁盘中提取目标目录的内容...
robocopy "%MOUNTED_DRIVE%\%RELATIVE_SOURCE%" "%DESTINATION%" /MIR /R:3 /W:5
if %ERRORLEVEL% GEQ 8 (
    echo 从挂载的虚拟磁盘提取目标目录失败，请检查日志。
    goto :EOF
) else (
    echo 文件成功从挂载的虚拟磁盘提取到目标目录！
)

:: 卸载 VHD 文件
echo 正在卸载 VHD 文件...
echo select vdisk file="%VHD_FILE%" > unmount_vhd.txt
echo detach vdisk >> unmount_vhd.txt
diskpart /s unmount_vhd.txt
if %ERRORLEVEL% NEQ 0 (
    echo 无法卸载 VHD 文件，请手动检查。
    goto :EOF
)

:: 删除卷影快照
echo 正在删除卷影快照...

:: 删除 F: 分区上的所有卷影快照
@REM vssadmin delete shadows /for=%TEMP_BACKUP_VOLUME% /quiet

:: 删除新增的卷影快照
if exist %NEW_SHADOW_ID% (
    for /f "tokens=3" %%I in (%NEW_SHADOW_ID%) do (
        echo 正在删除卷影快照 ID:%%I
        vssadmin delete shadows /shadow=%%I /quiet
    )
    echo 新增的卷影快照已成功删除。
) else (
    echo 未找到新增的卷影快照 ID。
)

:: 清理临时文件
if exist %SHADOW_ID_BEFORE% del /f /q %SHADOW_ID_BEFORE%
if exist %SHADOW_ID_AFTER% del /f /q %SHADOW_ID_AFTER%
if exist %NEW_SHADOW_ID% del /f /q %NEW_SHADOW_ID%

:: 如果需要删除所有临时卷影备份则不跳过下面的语句.
goto :EOF

:: 删除所有使用 wbadmin 创建的备份
wbadmin delete backup -keepVersions:0 -quiet

:: 如果需要删除特定卷影快照
:: for /f "tokens=3" %%I in ('vssadmin list shadows ^| findstr /i "Shadow Copy ID"') do set "SHADOW_ID=%%I"
:: vssadmin delete shadows /shadow=%SHADOW_ID% /quiet


echo 卷影快照已成功删除。
goto :EOF

pause

:: 提示完成
pause
goto :EOF