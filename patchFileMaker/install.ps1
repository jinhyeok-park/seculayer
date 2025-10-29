# CloudESM Patch Creator - 자동 설치 스크립트
# 실행: .\install.ps1

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  CloudESM Patch Creator - Auto Installer" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Cyan

# 1. 현재 스크립트 위치 확인
$scriptPath = $PSScriptRoot
$patchScriptPath = Join-Path $scriptPath "create_patch.ps1"

if (-not (Test-Path $patchScriptPath)) {
    Write-Host "❌ Error: create_patch.ps1 not found in current directory!" -ForegroundColor Red
    Write-Host "   Please run this installer from the Scripts folder." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found create_patch.ps1 at: $scriptPath" -ForegroundColor Green

# 2. PowerShell 실행 정책 확인
$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "`nCurrent Execution Policy: $executionPolicy" -ForegroundColor Yellow

if ($executionPolicy -eq "Restricted" -or $executionPolicy -eq "AllSigned") {
    Write-Host "`n⚠️  PowerShell execution policy needs to be changed." -ForegroundColor Yellow
    $changePolicy = Read-Host "Change to 'RemoteSigned'? (Y/N)"
    
    if ($changePolicy -eq "Y" -or $changePolicy -eq "y") {
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "✓ Execution policy changed to RemoteSigned" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to change execution policy. Please run as Administrator:" -ForegroundColor Red
            Write-Host "   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "⚠️  Installation cancelled. Execution policy must be changed." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "✓ Execution policy is OK" -ForegroundColor Green
}

# 3. PowerShell 프로파일 확인 및 생성
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  Setting up PowerShell Profile" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Cyan

if (-not (Test-Path $PROFILE)) {
    Write-Host "Creating PowerShell profile..." -ForegroundColor Yellow
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Host "✓ Profile created at: $PROFILE" -ForegroundColor Green
} else {
    Write-Host "✓ Profile exists at: $PROFILE" -ForegroundColor Green
}

# 4. 기존 설정 확인
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

$hasFunction = $profileContent -match "function Create-Patch"
$hasAlias = $profileContent -match "Set-Alias.*patch.*Create-Patch"

if ($hasFunction -and $hasAlias) {
    Write-Host "`n⚠️  Patch creator is already installed in your profile." -ForegroundColor Yellow
    $reinstall = Read-Host "Reinstall? (Y/N)"
    
    if ($reinstall -ne "Y" -and $reinstall -ne "y") {
        Write-Host "`n✓ Installation skipped. Already installed!" -ForegroundColor Green
        exit 0
    }
    
    # 기존 설정 제거
    $profileContent = $profileContent -replace "(?ms)# CloudESM Patch Creator.*?(?=\r?\n\r?\n|$)", ""
    $profileContent = $profileContent -replace "function Create-Patch \{[^\}]*\}", ""
    $profileContent = $profileContent -replace "Set-Alias -Name patch -Value Create-Patch", ""
    $profileContent = $profileContent.Trim()
}

# 5. 프로파일에 함수 추가
$configBlock = @"

# CloudESM Patch Creator
function Create-Patch {
    & "$patchScriptPath" @args
}
Set-Alias -Name patch -Value Create-Patch

# UTF-8 Encoding for Korean support
`$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
"@

$profileContent = $profileContent.TrimEnd() + "`n" + $configBlock

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8

Write-Host "`n✓ PowerShell profile updated successfully!" -ForegroundColor Green

# 6. 설치 완료 메시지
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "  Installation Complete! ✓" -ForegroundColor Green
Write-Host "===============================================`n" -ForegroundColor Cyan

Write-Host "📍 Installation Location:" -ForegroundColor Yellow
Write-Host "   $scriptPath`n" -ForegroundColor White

Write-Host "🚀 How to Use:" -ForegroundColor Yellow
Write-Host "   1. Restart PowerShell (or run: . `$PROFILE)" -ForegroundColor White
Write-Host "   2. Go to any project folder:" -ForegroundColor White
Write-Host "      cd C:\work\your-project" -ForegroundColor Gray
Write-Host "   3. Run:" -ForegroundColor White
Write-Host "      patch" -ForegroundColor Cyan
Write-Host "      (or: Create-Patch)" -ForegroundColor Gray

Write-Host "`n📖 Documentation:" -ForegroundColor Yellow
Write-Host "   README.md - Full documentation" -ForegroundColor White
Write-Host "   QUICKSTART.txt - Quick start guide`n" -ForegroundColor White

$reload = Read-Host "Reload profile now? (Y/N)"
if ($reload -eq "Y" -or $reload -eq "y") {
    . $PROFILE
    Write-Host "`n✓ Profile reloaded! You can now use 'patch' command." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Please restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
}

Write-Host "`n===============================================`n" -ForegroundColor Cyan

