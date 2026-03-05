# --- FINAL STEAM MOD AUTO-INSTALLER ---
# 1. Check for Admin Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    return
}

# 2. Detect Steam Path & Setup Folders
$SteamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
if (-not $SteamPath) { $SteamPath = "C:\Program Files (x86)\Steam" }
$PluginsPath = Join-Path $SteamPath "plugins"
$DownloadFolder = "$HOME\Downloads\SteamModSetup"

if (!(Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }
if (!(Test-Path $PluginsPath)) { New-Item -ItemType Directory -Path $PluginsPath | Out-Null }

# 3. Handle Steam Process
if (Get-Process -Name "Steam" -ErrorAction SilentlyContinue) {
    Write-Host "Stopping Steam for installation..." -ForegroundColor Yellow
    Stop-Process -Name "Steam" -Force
    Start-Sleep -Seconds 2
}

# 4. Verify VC++ Redistributables (Required for SteamTools/Millennium)
# This checks for the 2015-2022 Redistributable
$VCInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" -ErrorAction SilentlyContinue
if (!$VCInstalled) {
    Write-Host "Warning: VC++ Redistributable not detected. Downloading..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "$DownloadFolder\vc_redist.exe"
    Start-Process -FilePath "$DownloadFolder\vc_redist.exe" -ArgumentList "/install /quiet /norestart" -Wait
}

# 5. Component Installations
Write-Host "Step 1/3: Installing Millennium..." -ForegroundColor Magenta
Invoke-RestMethod -Uri "https://steambrew.app/install.ps1" | Invoke-Expression

Write-Host "Step 2/3: Installing SteamTools-NG..." -ForegroundColor Magenta
$repo = "calendulish/steam-tools-ng"
$asset = (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest").assets | Where-Object { $_.name -like "*windows-x86_64.zip" -or $_.name -like "*-latest.exe" }
$zipPath = Join-Path $DownloadFolder $asset.name
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
if ($asset.name -like "*.zip") {
    Expand-Archive -Path $zipPath -DestinationPath $SteamPath -Force
} else {
    Start-Process -FilePath $zipPath -ArgumentList "/S" -Wait
}

Write-Host "Step 3/3: Installing LuaTools Plugin..." -ForegroundColor Magenta
Invoke-RestMethod -Uri "https://luatools.vercel.app/install-plugin.ps1" | Invoke-Expression

# 6. Finalize & Restart
Write-Host "`nAll components installed successfully!" -ForegroundColor Green
Start-Process -FilePath (Join-Path $SteamPath "steam.exe")
Write-Host "Steam is restarting..."
