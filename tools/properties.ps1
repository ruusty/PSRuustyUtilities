# Set path that will not fail, 2 levels up from  LOCALAPPDATA
#e.g. LOCALAPPDATA=C:\Users\Russell\AppData\Local
# Should be a local disk
$Hostname = (Get-WmiObject -Class Win32_ComputerSystem -Property Name).Name

$poshModFolder = ".PowershellModules"
if ($Hostname -like "COVM*") {
    #Ched Servers
    $installRootDirPath = "$env:ProgramFiles\Ched Services\posh\Modules"
}
else {
    $installRootDirPath = $((Split-Path -Path $env:LOCALAPPDATA) | Split-Path) | Join-Path -child $poshModFolder
}


$moduleName = "Ruusty.ReleaseUtilities" #Top filepath in zip file
$moduleDirPath = Join-Path -Path $installRootDirPath -ChildPath $moduleName
$ZipName = "PSRuustyUtilities.zip"

$config_vars += @(
    'installRootDirPath'
    , 'moduleName'
    , 'moduleDirPath'
    , 'ZipName'
)

$config_vars | Get-Variable | Sort-Object -unique -property "Name" | Select-Object Name, value | Format-Table | Out-Host