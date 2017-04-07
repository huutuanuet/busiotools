@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

CALL WHOAMI.EXE /GROUPS | FIND.EXE /I "S-1-16-12288" >nul
IF ERRORLEVEL 1 (
    ECHO This script must be run from an elevated prompt.
    ECHO Script will exit now....
    EXIT /B 1
)

echo First stopping any duplicate traces that might already be running...
logman stop SensorsTrace -ets >nul
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\SensorsCx0102\Parameters" /f /v VerboseOn /t REG_DWORD /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\SensorsHIDClassDriver\Parameters" /f /v VerboseOn /t REG_DWORD /d 1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF\Services\SdoV2\Parameters" /f /v VerboseOn /t REG_DWORD /d 1
logman start SensorsTrace -ets -o %SystemRoot%\Tracing\SensorsTrace.etl -nb 128 640 -bs 128 -f bincirc -max 250 >nul
rem SensorsHid
logman update trace SensorsTrace -p "{32e38bd8-ac95-4605-894e-a5d815ca0f3b}" 0xffffffffffffffff 0xff -ets >nul
rem SensorService and class extension
logman update trace SensorsTrace -p "{c88b592b-6090-480f-a839-ca2434de5844}" 0xffffffffffffffff 0xff -ets >nul
rem Desktop SensrSvc
logman update trace SensorsTrace -p "{49DA058C-1384-4e57-8915-070F1B8C8AD2}" 0xffffffffffffffff 0xff -ets >nul
rem Desktop RotMgr
logman update trace SensorsTrace -p "{1ADF4F66-3AE0-43B1-BEC0-C7D891A77AC5}" 0xffffffffffffffff 0xff -ets >nul
rem Windows V1 Sensor Class Extension
logman update trace SensorsTrace -p "{d4575dd5-963b-43c6-8c68-8b070b8692fc}" 0xffffffffffffffff 0xff -ets >nul
rem Windows V1 Sensors API
logman update trace SensorsTrace -p "{b12f2c9f-d3a1-447b-92f8-dca5f6c31429}" 0xffffffffffffffff 0xff -ets >nul
rem Windows V2 Sensors API
logman update trace SensorsTrace -p "{096772ba-b6d9-4c54-b776-3d070efb40ec}" 0xffffffffffffffff 0xff -ets >nul
echo Tracing has been started.  
echo ===========================
echo Repro your scenario now. Once complete, press any key to stop tracing.
echo ===========================
pause
echo Stopping trace...
logman stop SensorsTrace -ets >nul
echo Now collecting version info
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v BuildLabEX >> %SystemRoot%\Tracing\BuildNumber.txt
powershell "(dir %SYSTEMROOT%\system32\drivers\UMDF\SensorsHid.dll).VersionInfo | fl" >> %SystemRoot%\Tracing\BuildNumber.txt
dir /s %SystemRoot%\LiveKernelReports\* >> %SystemRoot%\Tracing\BuildNumber.txt
start %SystemRoot%\Tracing