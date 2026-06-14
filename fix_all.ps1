# fix_all.ps1 — Авто-исправление всех ошибок в проекте

Write-Host "Fixing imports and errors..." -ForegroundColor Cyan

# Функция для замены текста в файле
function Fix-File($path, $old, $new) {
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        if ($content -match [regex]::Escape($old)) {
            $content = $content.Replace($old, $new)
            Set-Content $path $content -NoNewline
            Write-Host "  Fixed: $path" -ForegroundColor Green
        }
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. Исправляем импорты (features/core → core)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    # features/core → core
    if ($content -match "features/core/") {
        $content = $content -replace "features/core/", "core/"
        $changed = $true
    }
    
    # sl<...> → sl.get<...>
    if ($content -match 'sl<') {
        $content = $content -replace 'sl<([^>]+)>\(\)', 'sl.get<$1>()'
        $changed = $true
    }
    
    if ($changed) {
        Set-Content $file.FullName $content -NoNewline
        Write-Host "  Fixed imports: $($file.Name)" -ForegroundColor Green
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. Исправляем конкретные файлы
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# app.dart — themeModeProvider
$app = "lib/app.dart"
if (Test-Path $app) {
    $content = Get-Content $app -Raw
    $content = $content -replace "themeModeProvider", "settingsProvider.select((s) => s.themeMode)"
    Set-Content $app $content -NoNewline
    Write-Host "  Fixed: app.dart" -ForegroundColor Green
}

# network_info.dart — utf8
$net = "lib/core/network/network_info.dart"
if (Test-Path $net) {
    $content = Get-Content $net -Raw
    $content = $content -replace "utf8", "Utf8Codec()"
    Set-Content $net $content -NoNewline
    # Добавляем импорт
    $content = "import 'dart:convert';`r`n" + $content
    Set-Content $net $content -NoNewline
    Write-Host "  Fixed: network_info.dart" -ForegroundColor Green
}

# connect_vpn.dart — удаляем const и чиним switch
$conn = "lib/vpn_engine/domain/usecases/connect_vpn.dart"
if (Test-Path $conn) {
    $content = Get-Content $conn -Raw
    $content = $content -replace "const Failure", "Failure"
    $content = $content -replace "const VpnConnectionFailure", "VpnConnectionFailure"
    $content = $content -replace "import '../../../../core/errors/failures.dart';", "import '../../../../core/errors/failures.dart';`r`nimport '../../../../vpn_engine/domain/entities/vpn_protocol.dart';"
    Set-Content $conn $content -NoNewline
    Write-Host "  Fixed: connect_vpn.dart" -ForegroundColor Green
}

# app_theme.dart — CardTheme → CardThemeData
$theme = "lib/core/theme/app_theme.dart"
if (Test-Path $theme) {
    $content = Get-Content $theme -Raw
    $content = $content -replace "CardTheme(", "CardThemeData("
    $content = $content -replace "DialogTheme(", "DialogThemeData("
    Set-Content $theme $content -NoNewline
    Write-Host "  Fixed: app_theme.dart" -ForegroundColor Green
}

# server_repository_impl.dart — const Result.success → Result.success
$srv = "lib/features/servers/data/repositories/server_repository_impl.dart"
if (Test-Path $srv) {
    $content = Get-Content $srv -Raw
    $content = $content -replace "const Result.success", "Result.success"
    Set-Content $srv $content -NoNewline
    Write-Host "  Fixed: server_repository_impl.dart" -ForegroundColor Green
}

# subscription_repository_impl.dart — const Result.success → Result.success
$sub = "lib/features/subscriptions/data/repositories/subscription_repository_impl.dart"
if (Test-Path $sub) {
    $content = Get-Content $sub -Raw
    $content = $content -replace "const Result.success", "Result.success"
    Set-Content $sub $content -NoNewline
    Write-Host "  Fixed: subscription_repository_impl.dart" -ForegroundColor Green
}

# get_best_server.dart — возвращаемый тип
$best = "lib/features/servers/domain/usecases/get_best_server.dart"
if (Test-Path $best) {
    $content = Get-Content $best -Raw
    $content = $content -replace "Future<Result<Server>>", "Future<Result<List<Server>>>"
    Set-Content $best $content -NoNewline
    Write-Host "  Fixed: get_best_server.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! Run: flutter run -d windows" -ForegroundColor Green