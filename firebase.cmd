@echo off
REM Wrapper: firepit's .exe does not forward CLI args (init/deploy fail with MODULE_NOT_FOUND).
REM Uses portable Node + the firebase-tools install under %USERPROFILE%\.cache\firebase.
set "NODE=%USERPROFILE%\.cache\firebase\real-node\node-v20.18.2-win-x64\node.exe"
set "FB=%USERPROFILE%\.cache\firebase\tools\lib\node_modules\firebase-tools\lib\bin\firebase.js"
if not exist "%NODE%" (
  echo Missing portable Node at:
  echo   %NODE%
  echo Re-download from https://nodejs.org/dist/v20.18.2/node-v20.18.2-win-x64.zip
  exit /b 1
)
if not exist "%FB%" (
  echo Missing firebase-tools at:
  echo   %FB%
  echo Run .\firebase-tools-instant-win.exe once so it installs tools, then retry.
  exit /b 1
)
"%NODE%" "%FB%" %*
