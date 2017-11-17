Clear-Host;
$Autostart = Read-Host "Do you want to add script to autostart? (Y/n)";

function Add-ScriptToStartup () {
    $WshShell = New-Object -comObject WScript.Shell;
    $Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WallpaperSync.lnk");
    $Shortcut.TargetPath = "$PSScriptRoot\..\Launcher\Launcher.vbs";
    $Shortcut.WorkingDirectory = "$PSScriptRoot\..\Launcher";
    $Shortcut.Save();
    Write-Host "Script was added to autostart";
    Read-Host; 
}

switch ($Autostart) {
    "y" { Add-ScriptToStartup }
    Default { Write-Host "Nothing to do. Press any key to continue"; Read-Host; }
}