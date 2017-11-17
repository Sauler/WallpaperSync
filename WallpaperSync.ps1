function global:OnLockscreenWallpaperChange () {
    Write-Host "Event"
    # Load desktop wallpaper functions
    $DesktopWallpaperFunctionsPath = "$PSScriptRoot\DesktopWallpaper";
    Set-Location -Path $DesktopWallpaperFunctionsPath;
    . .\DesktopWallpaper.ps1

    # Load lockscreen wallpaper functions
    $LockscreenWallpaperFunctionsPath = "$PSScriptRoot\LockscreenWallpaper";
    Set-Location -Path $LockscreenWallpaperFunctionsPath;
    . .\LockscreenWallpaper.ps1

    # Get lockscreen wallpaper path
    $LockscreenWallpaperPath = Get-LockscreenWallpaper;

    if (!(Test-Path $LockscreenWallpaperPath)) {
        Write-Host "Wallpaper does not exists!";
        return;
    } else {
        # Set desktop wallpaper
        Set-DesktopWallpaper -NewWallpaperPath $LockscreenWallpaperPath;  
    } 
}

# Update wallpaper on script startup
OnLockscreenWallpaperChange;

# Get user SID
Add-Type -AssemblyName "System.DirectoryServices.AccountManagement"
$userSID = ([System.DirectoryServices.AccountManagement.UserPrincipal]::Current).Sid;

# Register lockscreen wallaper change listener
$EventQuery = "SELECT * FROM RegistryTreeChangeEvent WHERE Hive='HKEY_LOCAL_MACHINE' AND RootPath='SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Authentication\\LogonUI\\Creative'";
Register-WmiEvent -Query $EventQuery -SourceIdentifier LockscreenWallaperListener -Action { OnLockscreenWallpaperChange };

$EventQuery = "SELECT * FROM RegistryTreeChangeEvent  WHERE Hive='HKEY_LOCAL_MACHINE' AND RootPath='SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\SystemProtectedUserData\\$userSID\\AnyoneRead\\LockScreen'";
Register-WmiEvent -Query $EventQuery -SourceIdentifier LockScreenWallpaperListener1 -Action { OnLockscreenWallpaperChange }  

# Wait for lockscreen wallpaper change
while ($true) {
   Wait-Event -SourceIdentifier "LockscreenWallaperListener";
}