write-host chocolateyPackageFolder  =$env:chocolateyPackageFolder
write-host chocolateyPackageName    =$env:chocolateyPackageName
write-host chocolateyPackageVersion =$env:chocolateyPackageVersion

#write-host `$ErrorActionPreference=$ErrorActionPreference
#write-host `$VerbosePreference=$VerbosePreference

$tools = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
.  $(join-path $tools "properties.ps1")

$ZipPath = $(join-path $tools $ZipName)

if (!(Test-Path $installRootDirPath)) { New-Item $installRootDirPath -ItemType Directory -force | Out-Null }
#Remove everything under $moduleDirPath
$moduleDirPath = Join-Path -Path $installRootDirPath -ChildPath $moduleName
if (Test-Path $moduleDirPath) { Remove-Item -path $(Join-Path -Path $moduleDirPath -ChildPath "*") -Recurse -Force }

Get-ChocolateyUnzip -PackageName $env:chocolateyPackageName -FileFullPath $ZipPath -Destination $installRootDirPath
$psModulePath = [Environment]::GetEnvironmentVariable('PSModulePath','Machine')

# if installation dir path is not already in path then add it.
if(!($psModulePath.Split(';').Contains($installRootDirPath))){
  Write-Debug "adding $installRootDirPath to '$env:PSModulePath'"
    # trim trailing semicolon if exists
    $psModulePath = $psModulePath.TrimEnd(';');
    # append path
    $psModulePath = $psModulePath + ";$installRootDirPath"
    # save
    Install-ChocolateyEnvironmentVariable -variableName "PSModulePath" -variableValue $psModulePath -variableType 'Machine'
    # make effective in current session
    #$env:PSModulePath = $env:PSModulePath + ";$installModulesDirPath"
}
