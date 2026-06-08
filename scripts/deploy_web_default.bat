@echo off
setlocal

echo [1/2] Building Flutter web (release)...
call flutter build web --release
if errorlevel 1 (
  echo Build failed. Deployment aborted.
  exit /b 1
)

echo [2/2] Deploying to default Firebase Hosting site...
call firebase deploy --only hosting
if errorlevel 1 (
  echo Deploy failed.
  exit /b 1
)

echo Default hosting deployment completed.
endlocal
