# setup_singbox.ps1
# Скачивает Sing-Box для Windows

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Downloading Sing-Box for Vortex VPN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Создаём папку build/windows
Write-Host "[1/3] Creating folders..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "build\windows" | Out-Null
Write-Host "      Done!" -ForegroundColor Green

# 2. Скачиваем Sing-Box
Write-Host "[2/3] Downloading sing-box..." -ForegroundColor Yellow
$url = "https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-windows-amd64.zip"
$zipPath = "build\singbox.zip"

try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Write-Host "      Downloaded!" -ForegroundColor Green
} catch {
    Write-Host "      ERROR: Failed to download. Check internet connection." -ForegroundColor Red
    Write-Host "      URL: $url" -ForegroundColor Red
    pause
    exit 1
}

# 3. Распаковываем
Write-Host "[3/3] Extracting..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $zipPath -DestinationPath "build\windows" -Force
    Remove-Item $zipPath
    Write-Host "      Extracted!" -ForegroundColor Green
} catch {
    Write-Host "      ERROR: Failed to extract." -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Sing-Box installed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Проверяем версию
if (Test-Path "build\windows\sing-box.exe") {
    Write-Host "Version check:" -ForegroundColor Cyan
    & ".\build\windows\sing-box.exe" version
} else {
    Write-Host "Checking for alternative filename..." -ForegroundColor Yellow
    
    # Иногда в архиве другой путь
    $files = Get-ChildItem -Path "build\windows" -Recurse -Filter "*.exe"
    if ($files.Count -gt 0) {
        Write-Host "Found: $($files[0].FullName)" -ForegroundColor Green
        & $files[0].FullName version
    } else {
        Write-Host "ERROR: sing-box.exe not found in build/windows/" -ForegroundColor Red
        Write-Host "Files in folder:" -ForegroundColor Yellow
        Get-ChildItem -Path "build\windows" -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }
    }
}

Write-Host ""
Write-Host "You can now run the app with: flutter run -d windows" -ForegroundColor Cyan
pause