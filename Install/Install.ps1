param([switch]$AsAdmin)

function Is-Admin () {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator");
}

if ($AsAdmin -and !(Is-Admin)) 
{
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -AsAdmin' -f ($myinvocation.MyCommand.Definition));
    Exit;
} 

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0, [switch]$NoNewLine) {
    $DefaultColor = $Color[0];
    if ($LinesBefore -ne 0) {
        for ($i = 0; $i -lt $LinesBefore; $i++) {
            Write-Host "`n" -NoNewline;
        }
    } # Add empty line before  

    if ($StartTab -ne 0) {
        for ($i = 0; $i -lt $StartTab; $i++) {
            Write-Host "`t" -NoNewLine;
        }
    }  # Add TABS before text 

    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine;
        } 
    } else {
        for ($i = 0; $i -lt $Color.Length ; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine;
        }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine;
        }
    }
    if (!($NoNewLine)) {
        Write-Host;
    }
    if ($LinesAfter -ne 0) {
        for ($i = 0; $i -lt $LinesAfter; $i++) {
            Write-Host "`n";
        }
    }  # Add empty line after   
}

$script:DefaultInstallDir = Resolve-Path -Path "$PSScriptRoot\..";
$script:InstallDir = $DefaultInstallDir;
$script:AddToStartup = "True";
$script:InstallForAllUsers = "False";

function Write-Header () {
    Clear-Host;
    Write-Color -Text ":::::::::::::::::::::::::::: ", "WallpaperSync ", "install script", " ::::::::::::::::::::::::::::" -Color Green, Yellow, White, Green;   
}

function Update-Settings () {
    if ($script:InstallDir -ne $script:DefaultInstallDir) {
        $script:InstallDir = "$script:InstallDir\WallpaperSync"; 
    }  
}

function Write-Settings () {
    Write-Color -Text "==> ", "Script settings" -Color Green, White;
    Write-Color -Text "--> ", "Install directory -> ", $script:InstallDir -Color Green, White, Red -StartTab 1;
    Write-Color -Text "--> ", "Add to startup -> ", $script:AddToStartup -Color Green, White, Red -StartTab 1;  
    Write-Color -Text "--> ", "Install for all users -> ", $script:InstallForAllUsers -Color Green, White, Red -StartTab 1;  
}

function Show-InstallMenu () {
    while($true) {
        Clear-Host;
        
        Write-Header;
        Update-Settings;
        Write-Settings;
        Write-Host;
        Write-Color "[I]nstall", " | ", "[C]hange settings", " | ", "[R]eset settings", " | ", "[E]xit" -Color Yellow, White, Yellow, White, Yellow, White, Yellow;            

        Write-Color -Text "Option: " -Color Yellow -NoNewLine; $option = Read-Host;
        
        switch ($option) {
            'I' { Install }
            'C' { Change-Settings }
            'R' { Reset-Settings }
            'E' { return }
            Default {}
        }
    }
}

function Install () {
    Clear-Host;
    Write-Header;
    Write-Settings;
    if ($script:InstallDir -ne $script:DefaultInstallDir) {
        Write-Color -Text "==> ", "Copying files..." -Color Green, White;
        if (!(Test-Path -Path $script:InstallDir)) {
            New-Item -Path $script:InstallDir -Force -Type Directory | Out-Null;
            if (!(Test-Path -Path $script:InstallDir)) {
                Write-Color -Text "--> ", "`'$script:InstallDir`' does not exists." -Color Green, Red -StartTab 1;
                Write-Color -Text "--> ", "Press any key to exit..." -Color Green, White -StartTab 1;
                Read-Host;
                return;
            }
        }
        Copy-Item -Path $script:DefaultInstallDir -Filter "*" -Recurse -Destination "$script:InstallDir\.." -Container -Force;
    }  
    
    $StartupPath = "";
    if ($script:InstallForAllUsers -eq "True") {
        $StartupPath = "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup";
    } else {
        $StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup";
    }

    if ($script:AddToStartup -eq "True") {
        Write-Color -Text "==> ", "Adding script to startup..." -Color Green, White;
        $WshShell = New-Object -comObject WScript.Shell;
        $Shortcut = $WshShell.CreateShortcut("$StartupPath\WallpaperSync.lnk");
        $Shortcut.TargetPath = "$script:InstallDir\Launcher\Launcher.vbs";
        $Shortcut.WorkingDirectory = "$script:InstallDir\Launcher";
        $Shortcut.Save();  
    }

    Write-Color -Text "==> ", "Running script..." -Color Green, White;
    Start-Process "$script:InstallDir\Launcher\Launcher.vbs" -WorkingDirectory "$script:InstallDir\Launcher"; 
    Write-Color -Text "==> ", "Installation done" -Color Green, White;
    Read-Host;
}

function Change-Settings () {
    Clear-Host;
    Write-Header;
    Write-Host "Click ENTER to leave current value. If you want install this script for all users select path that is accessible for all users";

    Write-Color -Text "Install directory (", $script:InstallDir, ") -> " -Color Green, White, Green -NoNewLine; 
    $InstallDirTemp = Read-Host;
    if ($InstallDirTemp -ne "") {$script:InstallDir = $InstallDirTemp};

    Write-Color -Text "Add to startup (", $script:AddToStartup, ") -> " -Color Green, White, Green -NoNewLine; 
    $AddToStartupTemp = Read-Host;
    if ($AddToStartupTemp -ne "") {$script:AddToStartup = $AddToStartupTemp};

    Write-Color -Text "Add to startup (", $script:InstallForAllUsers, ") -> " -Color Green, White, Green -NoNewLine;
    if (Is-Admin) {
        $InstallForAllUsersTemp = Read-Host;
        if ($InstallForAllUsersTemp -ne "") {$script:InstallForAllUsers = $InstallForAllUsersTemp};
    } else {
        Write-Color -Text "Cannot change! Run ", "Install_AsAdmin.bat", " if you want to install for all users!" -Color Yellow, White, Yellow;
        Read-Host;
    }
    
}

function Reset-Settings () {
    $script:InstallDir = $DefaultInstallDir;
    $script:AddToStartup = "True";
    $script:InstallForAllUsers = "False";
}

Show-InstallMenu;