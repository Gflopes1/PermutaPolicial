@echo off
setlocal EnableExtensions

REM Sempre executa a partir da pasta do script (permuta_policial/)
cd /d "%~dp0"

echo Building Flutter Web (producao)...
echo.

REM Gera web/version.json + meta tags em index.html
echo Atualizando versao (index.html + version.json)...
where node >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  node update-version.js
  if errorlevel 1 (
    echo ERRO: update-version.js falhou no pre-build.
    exit /b 1
  )
) else (
  echo AVISO: Node.js nao encontrado. Pulando atualizacao de versao.
  echo         Execute manualmente: node update-version.js
)

echo.
echo Limpando build anterior...
call flutter clean
if errorlevel 1 exit /b 1

echo.
echo Obtendo dependencias...
call flutter pub get
if errorlevel 1 exit /b 1

echo.
echo Fazendo build web (PRODUCAO)...
call flutter build web --release --dart-define=ENV=prod --pwa-strategy=none
if errorlevel 1 (
  echo ERRO: flutter build web falhou.
  exit /b 1
)

echo.
echo Pos-build: fingerprint main.dart.js + cache bust flutter_bootstrap...
where node >nul 2>&1
if %ERRORLEVEL% EQU 0 (
  node update-version.js --post-build
  if errorlevel 1 (
    echo ERRO: update-version.js falhou no post-build.
    exit /b 1
  )
) else (
  echo AVISO: Node.js nao encontrado. Rode: node update-version.js --post-build
)

echo.
if exist "build\web\version.json" (
  echo version.json gerado em build\web\version.json
) else (
  echo AVISO: build\web\version.json ausente - confira se node update-version.js rodou.
)

echo.
echo Build concluido com sucesso!
echo Arquivos em: build\web\
echo.
echo Proximos passos:
echo    1. Copiar build\web\* para o public_html do servidor
echo    2. Verificar Nginx (cache de main.dart.js)
echo    3. Testar: https://br.permutapolicial.com.br
echo.

if /i not "%~1"=="--no-pause" pause

endlocal
exit /b 0
