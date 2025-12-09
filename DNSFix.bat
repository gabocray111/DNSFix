:: DNSFix - Script creado por Gabocray111
:: Licencia MIT - ver LICENSE en el repositorio oficial
:: https://github.com/gabocray111/DNSFix

@echo off
title Diagnostico Avanzado de DNS y Conexion - Minecraft
setlocal enabledelayedexpansion

:: ------------------------------------------------------------
:: Configurable
:: ------------------------------------------------------------
echo ========================================================
echo  DIAGNOSTICO AVANZADO DE DNS Y CONEXION - Licencia MIT 
echo  Creado por Gabocray111 - github.com/gabocray111/DNSFix
echo ========================================================
set /p SERVER=Ingresa  el dominio o IP a diagnosticar 
set REPORTFILE=%~dp0diagnostico_dns_report.txt

:: ------------------------------------------------------------
:: Funciones / Helpers (simuladas en batch)
:: ------------------------------------------------------------
:: Comprueba si tenemos permisos de administrador.
net session >nul 2>&1
if %errorlevel% equ 0 (
    set ISADMIN=1
) else (
    set ISADMIN=0
)

cls
echo Servidor objetivo: %SERVER%
echo.

:: ------------------------------------------------------------
:: Paso 0: Comprobar si hay acceso a Internet (ping a 8.8.8.8)
:: ------------------------------------------------------------
echo [0] Verificando acceso a Internet (ping 8.8.8.8)...
ping 8.8.8.8 -n 1 >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [X] No se pudo contactar a 8.8.8.8.
    echo     -> Posibles causas: sin conexion, adaptador deshabilitado, VPN/Firewall bloqueando.
    echo.
    set /p c="Deseas intentar comprobar el adaptador de red y reintentar? (s/n): "
    if /I "%c%"=="s" (
        echo Listando adaptadores de red...
        netsh interface show interface
        echo.
        echo Intenta habilitar el adaptador si esta deshabilitado y luego presiona una tecla para reintentar.
        pause >nul
        echo Reintentando ping a 8.8.8.8...
        ping 8.8.8.8 -n 1
        if %errorlevel% neq 0 (
            echo Sigue sin respuesta. Abortando pruebas.
            pause
            goto cleanup
        )
    ) else (
        echo Abortando pruebas por falta de conexion.
        pause
        goto cleanup
    )
) else (
    echo [✓] El equipo tiene acceso a Internet.
)
echo.

:: ------------------------------------------------------------
:: Paso 1: Probar resolucion DNS con nslookup y categorizar errores
:: ------------------------------------------------------------
echo [1] Probando resolucion DNS del dominio %SERVER%...
nslookup %SERVER% > "%temp%\dns_tmp.txt" 2>&1

set DNS_ERROR=0
:: Buscamos mensajes comunes (variaciones en ingles/español)
findstr /I /C:"Non-existent domain" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=1
findstr /I /C:"name does not exist" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=1
findstr /I /C:"can't find" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=2
findstr /I /C:"Unknown host" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=2
findstr /I /C:"timed out" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=3
findstr /I /C:"server can't find" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=1
findstr /I /C:"No response from server" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=4
findstr /I /C:"no servers could be reached" "%temp%\dns_tmp.txt" >nul 2>&1 && set DNS_ERROR=4

if "%DNS_ERROR%"=="0" (
    echo [✓] El dominio se resolvio correctamente. Resultado nslookup:
    type "%temp%\dns_tmp.txt"
    echo.
) else (
    echo.
    echo ============================================================
    echo               ERROR DE RESOLUCION DNS DETECTADO
    echo ============================================================
    if "%DNS_ERROR%"=="1" (
        echo Tipo: Dominio inexistente.
        echo Explicacion: El servidor DNS indica que el dominio no existe. Puede ser un problema del registro DNS o un DNS que devuelve NXDOMAIN.
    )
    if "%DNS_ERROR%"=="2" (
        echo Tipo: Host no resuelto / Host desconocido.
        echo Explicacion: El sistema no pudo convertir el nombre a IP. Causas comunes: DNS malo, bloqueo por VPN/firewall, o error temporal.
    )
    if "%DNS_ERROR%"=="3" (
        echo Tipo: Tiempo de espera agotado para la consulta DNS.
        echo Explicacion: El DNS configurado no responde en tiempo. Puede indicar DNS caido o conexion inestable.
    )
    if "%DNS_ERROR%"=="4" (
        echo Tipo: No se pudieron contactar servidores DNS.
        echo Explicacion: No se obtuvo respuesta de los servidores DNS configurados.
    )
    echo.
    echo Opciones recomendadas:
    echo   1) Cambiar DNS a Google (8.8.8.8 / 8.8.4.4)
    echo   2) Cambiar DNS a Cloudflare (1.1.1.1 / 1.0.0.1)
    echo   3) Introducir DNS personalizado
    echo   4) Restaurar DNS automatico (DHCP)
    echo   5) Limpiar cache DNS (ipconfig /flushdns)
    echo   6) Reintentar pruebas sin cambios
    echo   7) Salir
    echo.
    set /p opt="Selecciona opcion (1-7): "
    if "%opt%"=="1" (
        set DNS1=8.8.8.8
        set DNS2=8.8.4.4
        goto apply_dns
    )
    if "%opt%"=="2" (
        set DNS1=1.1.1.1
        set DNS2=1.0.0.1
        goto apply_dns
    )
    if "%opt%"=="3" (
        set /p DNS1="Introduce DNS primario (IP): "
        set /p DNS2="Introduce DNS secundario (IP) [opcional, ENTER para omitir]: "
        goto apply_dns
    )
    if "%opt%"=="4" goto restore_dns
    if "%opt%"=="5" goto flushdns
    if "%opt%"=="6" goto rerun_nslookup
    goto cleanup
)

:: ------------------------------------------------------------
:: Si nslookup tuvo OK, o reintentos, continuamos a ping y pruebas
:: ------------------------------------------------------------
goto post_nslookup

:apply_dns
echo.
echo A punto de cambiar DNS a:
echo   Primario: %DNS1%
if defined DNS2 echo   Secundario: %DNS2%
echo.
set /p conf="Confirmas el cambio? (s/n): "
if /I not "%conf%"=="s" goto rerun_nslookup

:: Si no somos admin, reiniciar en admin
if "%ISADMIN%"=="0" (
    echo [!] Este cambio requiere permisos de administrador.
    echo Reiniciando el script con elevacion...
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '' -Verb runAs"
    exit
)

:: Obtenemos interfaz conectada (intenta detectar la interfaz con "Conectado" o "Connected")
for /f "tokens=1,* delims=:" %%A in ('netsh interface show interface ^| findstr /R /C:"Conectado" /C:"Connected"') do (
    set IFACE_LINE=%%B
)
:: Si IFACE_LINE esta vacio, listar y pedir al usuario
if not defined IFACE_LINE (
    echo No se pudo detectar automaticamente la interfaz. Lista de interfaces:
    netsh interface show interface
    set /p IFACE="Introduce el nombre exacto de la interfaz a modificar: "
) else (
    rem limpiar espacios
    for /f "tokens=* delims= " %%I in ("!IFACE_LINE!") do set IFACE=%%I
    rem IFACE puede contener mas texto; intentar tomar hasta la primera tabulacion o fin de linea
    for /f "tokens=1*" %%i in ("!IFACE!") do set IFACE=%%i
)

echo Aplicando DNS en la interfaz: "!IFACE!"
netsh interface ip set dns name="%IFACE%" static %DNS1% >nul 2>&1
if defined DNS2 netsh interface ip add dns name="%IFACE%" %DNS2% index=2 >nul 2>&1
echo DNS aplicados.
goto rerun_nslookup

:restore_dns
echo.
set /p conf="Restaurar DNS automaticos (DHCP) en la interfaz detectada? (s/n): "
if /I not "%conf%"=="s" goto rerun_nslookup
if "%ISADMIN%"=="0" (
    echo [!] Se requieren permisos de administrador.
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '' -Verb runAs"
    exit
)
for /f "tokens=1,* delims=:" %%A in ('netsh interface show interface ^| findstr /R /C:"Conectado" /C:"Connected"') do set IFACE_LINE=%%B
if not defined IFACE_LINE (
    netsh interface show interface
    set /p IFACE="Introduce el nombre exacto de la interfaz a modificar: "
) else (
    for /f "tokens=* delims= " %%I in ("!IFACE_LINE!") do set IFACE=%%I
    for /f "tokens=1*" %%i in ("!IFACE!") do set IFACE=%%i
)
echo Restaurando DNS a DHCP en "!IFACE!"...
netsh interface ip set dns name="%IFACE%" dhcp >nul 2>&1
echo Restaurado.
goto rerun_nslookup

:flushdns
echo.
set /p conf="Esto ejecutara 'ipconfig /flushdns'. Confirmar? (s/n): "
if /I not "%conf%"=="s" goto rerun_nslookup
ipconfig /flushdns
echo Caché DNS limpiada.
goto rerun_nslookup

:rerun_nslookup
echo.
echo Reintentando nslookup para %SERVER%...
nslookup %SERVER%
echo.
goto post_nslookup

:post_nslookup
:: ------------------------------------------------------------
:: Probar ping al servidor
:: ------------------------------------------------------------
echo [2] Probando ping al servidor %SERVER% (3 intentos)...
ping %SERVER% -n 3
if %errorlevel% equ 0 (
    echo [✓] Respuesta a ping detectada.
) else (
    echo [!] No hubo respuesta a ping.
    echo    -> Puede ser: firewall bloqueando ICMP, servidor que oculta ICMP, o problema de red.
)
echo.

:: ------------------------------------------------------------
:: Probar puerto 25565 (puerto Minecraft) usando PowerShell Test-NetConnection
:: ------------------------------------------------------------
echo [3] Probando puerto 25565 (Test-NetConnection)...
powershell -Command "Try { $r = Test-NetConnection -ComputerName '%SERVER%' -Port 25565 -WarningAction SilentlyContinue; if ($r -eq $null) { Write-Output 'Test-NetConnection no disponible'; exit 2 } ; $r | Select-Object -Property ComputerName,RemoteAddress,RemotePort,TcpTestSucceeded | Format-List } Catch { Write-Output 'Test-NetConnection fallo' }"
echo.

:: ------------------------------------------------------------
:: Traceroute (tracert)
:: ------------------------------------------------------------
set /p wanttr="Deseas ejecutar tracert hacia %SERVER%? (s/n): "
if /I "%wanttr%"=="s" (
    echo Ejecutando tracert (puede tardar)...
    tracert %SERVER%
    echo.
)

:: ------------------------------------------------------------
:: Generar informe opcional
:: ------------------------------------------------------------
set /p wantrep="Deseas guardar un informe con los resultados en %REPORTFILE% ? (s/n): "
if /I "%wantrep%"=="s" (
    echo Generando informe...
    (
    echo =========================== DIAGNOSTICO DNS - %DATE% %TIME% ===========================
    echo Servidor: %SERVER%
    echo.
    echo -- nslookup --
    nslookup %SERVER%
    echo.
    echo -- ping --
    ping %SERVER% -n 3
    echo.
    echo -- Test-NetConnection (puerto 25565) --
    powershell -Command "Try { Test-NetConnection -ComputerName '%SERVER%' -Port 25565 -WarningAction SilentlyContinue } Catch { Write-Output 'Test-NetConnection fallo' }"
    echo.
    echo -- interfaces --
    netsh interface show interface
    echo.
    echo =======================================================================
    ) > "%REPORTFILE%"
    echo Informe guardado en: %REPORTFILE%
    echo.
)

:: ------------------------------------------------------------
:: Sugerencias posteriores (acciones que el usuario puede tomar)
:: ------------------------------------------------------------
echo ============================================================
echo SUGERENCIAS:
echo  - Si cambiaste DNS y ahora funciona, conviene reiniciar el adaptador o PC.
echo  - Si nslookup falla con NXDOMAIN (dominio inexistente), revisa que el dominio exista o contacta al host.
echo  - Si Test-NetConnection muestra que el puerto 25565 esta cerrado, revisa firewall local/NAT/host.
echo  - Si tracert falla en un hop cercano a tu ISP, contacta a tu proveedor de Internet.
echo ============================================================
echo.

:cleanup
del "%temp%\dns_tmp.txt" >nul 2>&1
echo Proceso finalizado. Presiona una tecla para cerrar...
pause >nul
exit /b 0


