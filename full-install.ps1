# --- FINAL STEAM MOD AUTO-INSTALLER (VERIFIED MARCH 2026) ---

# 1. Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    return
}

# 2. Path Detection
$SteamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
if (-not $SteamPath) { $SteamPath = "C:\Program Files (x86)\Steam" }
$DownloadFolder = "$HOME\Downloads\SteamModSetup"
if (!(Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }

# 3. Kill Steam
if (Get-Process -Name "Steam" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "Steam" -Force
    Start-Sleep -Seconds 2
}

# 4. Step 1: Install Millennium
Write-Host "Installing Millennium..." -ForegroundColor Magenta
Invoke-RestMethod -Uri "https://steambrew.app/install.ps1" | Invoke-Expression
Start-Sleep -Seconds 3 # Buffer for folder creation

# 5. Step 2: Install SteamTools-NG (Auto-Identifying)
Write-Host "Installing SteamTools-NG..." -ForegroundColor Magenta
$repo = "calendulish/steam-tools-ng"
$assets = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest").assets
# Priority: .exe installer > .zip archive
$asset = ($assets | Where-Object { $_.name -like "*-latest.exe" })[0]
if (!$asset) { $asset = ($assets | Where-Object { $_.name -like "*windows-x86_64.zip" })[0] }

$destPath = Join-Path $DownloadFolder $asset.name
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $destPath

if ($asset.name -like "*.exe") {
    Start-Process -FilePath $destPath -ArgumentList "/S" -Wait
} else {
    Expand-Archive -Path $destPath -DestinationPath $SteamPath -Force
}

# 6. Step 3: Install LuaTools Plugin
Write-Host "Installing LuaTools Plugin..." -ForegroundColor Magenta
Invoke-RestMethod -Uri "https://luatools.vercel.app/install-plugin.ps1" | Invoke-Expression

# 7. Restart
Write-Host "`nSetup Complete! Restarting Steam..." -ForegroundColor Green
Start-Process -FilePath (Join-Path $SteamPath "steam.exe")
