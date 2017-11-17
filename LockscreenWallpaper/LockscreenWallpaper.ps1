function Get-LockscreenWallpaper () {
    Add-Type -AssemblyName "System.DirectoryServices.AccountManagement";
    $CurrentUser = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current;
    $UserSid = $CurrentUser.Sid;

    $LockscreenWallpaperRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Creative\$UserSid";
    $LockscreenWallpaperType = (Get-ItemProperty -Path $LockscreenWallpaperRegistryPath -Name RotatingLockScreenEnabled).RotatingLockScreenEnabled;

    # Spotlight wallpaper
    if ($LockscreenWallpaperType -eq 1) {
        $SpotlightWallpaperKeys = Get-Item -Path $LockscreenWallpaperRegistryPath;

        # Get latest spotlight wallpaper
        $SpotlightWallpaperKeysCount = $SpotlightWallpaperKeys.SubKeyCount;
        $SpotlightWallpaperKeyName = $SpotlightWallpaperKeys.GetSubKeyNames()[$SpotlightWallpaperKeysCount-1];
        $SpotlightWallaperPath = (Get-ItemProperty "$LockscreenWallpaperRegistryPath\$SpotlightWallpaperKeyName" -Name landscapeImage).landscapeImage;
        $LockscreenWallpaperPath = $SpotlightWallaperPath;
    } elseif ($LockscreenWallpaperType -eq 0) {
        $null = [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime];
        $LockscreenWallpaperPath = [Windows.System.UserProfile.LockScreen]::OriginalImageFile.AbsolutePath;
    }
    
    return $LockscreenWallpaperPath;
}