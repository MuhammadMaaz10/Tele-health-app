@echo off
setlocal

echo [1/2] Building Flutter web (release)...
call flutter build web --release
if errorlevel 1 (
  echo Build failed. Deployment aborted.
  exit /b 1
)

echo [2/2] Deploying to Firebase Hosting target: telehealthupdated...
call firebase deploy --only hosting:telehealthupdated
if errorlevel 1 (
  echo Deploy failed.
  exit /b 1
)

echo Deployment completed: https://telehealthupdated.web.app/
endlocal
