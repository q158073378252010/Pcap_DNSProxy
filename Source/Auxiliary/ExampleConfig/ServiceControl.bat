:: Pcap_DNSProxy service control batch
:: Pcap_DNSProxy, a local DNS server based on WinPcap and LibPcap
::
:: Author: Hugo Chan, Syrone Wong, Stzx, Chengr28
::

@chcp 65001
@echo off


:: Administrative permission check
net session >nul 2>nul
IF ERRORLEVEL 1 (
	color 4F
	echo Please run as Administrator.
	echo.
	pause & break
	echo.
	cls
)


:: Processor architecture and system version check
set Architecture=
IF %PROCESSOR_ARCHITECTURE%%PROCESSOR_ARCHITEW6432% == x86 (
	set Architecture=_x86
)
ver | findstr /L /I " 5." >nul
IF NOT ERRORLEVEL 1 (
	set Architecture=_XP
)
set Executable=Pcap_DNSProxy%Architecture%.exe
set ServiceName=PcapDNSProxyService


:: Command
set Command=%~1
IF NOT "%Command%" == "" (
	GOTO CASE_%Command%
)


:: Choice
:CHOICE
echo Pcap_DNSProxy service control batch
echo.
echo 1: Install service
echo 2: Uninstall service
echo 3: Start service
echo 4: Stop service
echo 5: Restart service
echo 6: Flush domain cache in Pcap_DNSProxy
echo 7: Flush domain cache in system only
echo 8: Exit
echo.
set /P UserChoice="Choose: "
set UserChoice=CASE_%UserChoice%
cd /D "%~dp0"
cls
GOTO %UserChoice%


:: Service install
:CASE_1
	CALL :DELETE_SERVICE
	ping 127.0.0.1 -n 3 >nul
	CALL :KILL_PROCESS
	ping 127.0.0.1 -n 3 >nul
	sc create %ServiceName% binPath= "%~dp0%Executable%" DisplayName= "PcapDNSProxy Service" start= auto
	%Executable% --first-setup
	sc description %ServiceName% "Pcap_DNSProxy, a local DNS server based on WinPcap and LibPcap"
	sc failure %ServiceName% reset= 0 actions= restart/5000/restart/10000//
	sc start %ServiceName%
	IF %ERRORLEVEL% EQU 0 (
		ipconfig /flushdns
	)
	CALL :CHECK_PROCESS
	IF "%Command%" == "" (
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Service uninstall
:CASE_2
	CALL :DELETE_SERVICE
	ping 127.0.0.1 -n 3 >nul
	CALL :KILL_PROCESS
	ipconfig /flushdns
	IF "%Command%" == "" (
		echo.
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Service start
:CASE_3
	sc query %ServiceName% >nul
	IF %ERRORLEVEL% EQU 0 (
		CALL :START_SERVICE
	) ELSE (
		color 4F
		echo Service not installed.
		echo.
	)
	IF "%Command%" == "" (
		pause
		color 07
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Service stop
:CASE_4
	CALL :STOP_SERVICE
	ping 127.0.0.1 -n 3 >nul
	ipconfig /flushdns
	IF "%Command%" == "" (
		echo.
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Service restart
:CASE_5
	CALL :STOP_SERVICE
	ping 127.0.0.1 -n 3 >nul
	CALL :KILL_PROCESS
	ping 127.0.0.1 -n 3 >nul
	CALL :START_SERVICE
	IF "%Command%" == "" (
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Flush domain cache(Pcap_DNSProxy)
:CASE_6
	CALL :CHECK_PROCESS
	%Executable% --flush-dns
	IF "%Command%" == "" (
		echo.
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Flush domain cache(System)
:CASE_7
	ipconfig /flushdns
	IF "%Command%" == "" (
		echo.
		pause
		cls
		GOTO :CHOICE
	) ELSE (
		EXIT
	)


:: Exit
:CASE_8
	color
	EXIT


:: Process check
:CHECK_PROCESS
	tasklist | findstr /L /I "%Executable%" >nul
	IF %ERRORLEVEL% NEQ 0 (
		color 4F
		echo.
		echo The program is not running, please check the configurations and error log.
		echo.
		pause
		color 07
		cls
		GOTO :CHOICE
	)
	echo.
GOTO :EOF


:: Process kill
:KILL_PROCESS
	tasklist | findstr /L /I "%Executable%" >nul && taskkill /F /IM %Executable% >nul
GOTO :EOF


:: Service start
:START_SERVICE
	sc query %ServiceName% >nul && ( sc query %ServiceName% | find "RUNNING" >nul || sc start %ServiceName% )
	IF %ERRORLEVEL% EQU 0 (
		ping 127.0.0.1 -n 3 >nul
		ipconfig /flushdns
		ping 127.0.0.1 -n 3 >nul
		CALL :CHECK_PROCESS
	)
GOTO :EOF


:: Service stop
:STOP_SERVICE
	sc query %ServiceName% >nul && ( sc query %ServiceName% | find "STOPPED" >nul || sc stop %ServiceName% )
GOTO :EOF


:: Service delete
:DELETE_SERVICE
	sc query %ServiceName% >nul && ( sc query %ServiceName% | find "STOPPED" >nul || sc stop %ServiceName% ) && sc delete %ServiceName%
GOTO :EOF
