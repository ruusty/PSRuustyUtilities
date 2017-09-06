<#
.SYNOPSIS

This is a psake script


.DESCRIPTION


 $ProjectName = [System.IO.Path]::GetFileName($PSScriptRoot)

#>
Framework '4.0'
Set-StrictMode -Version 4
$me = $MyInvocation.MyCommand.Definition
filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }

FormatTaskName "`r`n[------{0}------]`r`n"
#need to copy dll to a temp directory
function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  [string]$name = [System.Guid]::NewGuid()
  New-Item -ItemType Directory -Path (Join-Path $parent $name)
}
$tempDir = New-TemporaryDirectory;
Copy-Item -Path $(join-path $PSScriptRoot "CmdletRuusty\bin\Release\Ruusty.ReleaseUtilities.dll") -Destination $tempDir -Verbose 
Import-Module $(Join-Path $tempDir.FullName Ruusty.ReleaseUtilities.dll )

properties {
  $script:config_vars = @()
  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
    "GlobalPropertiesName"
     ,"GlobalPropertiesPath"
     ,"GitExe"
     ,"CoreDeliveryDirectory"
     ,"CoreReleaseStartDate"
     ,"CoreChocoFeed"
     ,"ProjectName"
     ,"ProjTopdir"
     ,"ProjBuildPath"
     ,"ProjDistPath"
     ,"ProjPackageListPath"
     ,"ProjPackageZipPath"
     ,"ProjHistoryPath"
     ,"ProjVersionPath"
     ,"ProjHistorySinceDate"
     ,"ProjDeliveryPath"
    ,"ProjPackageZipVersionPath"
    ,"sdlc"
  )
  $verbose = $false;
  $whatif = $false;
  $now = [System.DateTime]::Now
  write-verbose($("CurrentLocation={0}" -f $executionContext.SessionState.Path.CurrentLocation))
  $GlobalPropertiesName=$("GisOms.Chocolatey.properties.{0}.xml" -f $env:COMPUTERNAME)
  $GlobalPropertiesPath = Ruusty.ReleaseUtilities\Find-FileUp "GisOms.Chocolatey.properties.${env:COMPUTERNAME}.xml" -verbose
  Write-Host $('$GlobalPropertiesPath:{0}' -f $GlobalPropertiesPath)
  $GlobalPropertiesXML = New-Object XML
  $GlobalPropertiesXML.Load($GlobalPropertiesPath)

  $GitExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='git.exe']").value
  $7zipExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='tools.7zip']").value
  $ChocoExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='tools.choco']").value

  $CoreDeliveryDirectory = $GlobalPropertiesXML.SelectNodes("/project/property[@name='core.delivery.dir']").value
  $CoreChocoFeed = $GlobalPropertiesXML.SelectNodes("/project/property[@name='core.delivery.chocoFeed.dir']").value
  #$CoreDeliveryDirectory = Join-Path $CoreDeliveryDirectory "GisOms"   #todo Change to suite needs
  $CoreReleaseStartDate = $GlobalPropertiesXML.SelectNodes("/project/property[@name='GisOms.release.StartDate']").value
  $ProjectName = [System.IO.Path]::GetFileName($PSScriptRoot)
  $ProjTopdir = $PSScriptRoot
  $ProjBuildPath = Join-Path $ProjTopdir "Build"
  $ProjDistPath = Join-Path $ProjTopdir "Dist"
  $ProjPackageListPath = Join-Path $ProjTopdir "${ProjectName}.lis"
  $ProjPackageZipPath = Join-Path $ProjDistPath  "${ProjectName}.zip"
  #$ProjDeliveryPath = Join-Path $(Join-Path $CoreDeliveryDirectory ${ProjectName})  '${versionNum}'
  $ProjDeliveryPath = Join-Path $PSScriptRoot "..\Deploy"

  $ProjPackageZipVersionPath = Join-Path $ProjDeliveryPath  '${ProjectName}.${versionNum}.zip'  #Expand dynamically versionNum not set


  $ProjHistoryPath = Join-Path $ProjTopdir "${ProjectName}.git_history.txt"
  $ProjVersionPath = Join-Path $ProjTopdir "${ProjectName}.Build.Number"
  $ProjNuspecPath = Join-Path $ProjTopdir "${ProjectName}.nuspec"
  $ProjNuspecPkgVersionPath = Join-Path $ProjTopdir  '${ProjectName}.${versionNum}.nupkg'

  $ProjHistorySinceDate ="2015-05-01"

  Set-Variable -Name "sdlc" -Description "System Development Lifecycle Environment" -Value "UNKNOWN"
  $zipExe = "7z.exe"
  $zipArgs = 'a -bb2 -tzip "{0}" -ir0@"{1}"' -f $ProjPackageZipPath, $ProjPackageListPath # Get paths from file
  $zipArgs = 'a -bb2 -tzip "{0}" -ir0!*' -f $ProjPackageZipPath #Everything in $ProjBuildPath

  $zipArgs = 'a  -tzip "{0}" -ir0@"{1}"' -f $ProjPackageZipPath, $ProjPackageListPath # Get paths from file #7z.exe 9.38
  $zipArgs = 'a  -tzip "{0}" -ir0!*' -f $ProjPackageZipPath #Everything in $ProjBuildPath #7z.exe 9.38

  Write-Host "Verbose: $verbose"
  Write-Verbose "Verbose"

}

task default -depends build
task test-build -depends Show-Settings, clean,              git-history, set-version, compile, compile-nupkg
#, distribute 
task      build -depends  Show-Settings, clean, git-status, git-history, set-version, compile, tag-version, distribute

task clean-dirs {
  if ((Test-Path $ProjBuildPath)) { Remove-Item $ProjBuildPath -Recurse -force }
  if ((Test-Path $ProjDistPath))  { Remove-Item $ProjDistPath -Recurse -force }
}

task create-dirs {
  if (!(Test-Path $ProjBuildPath)) { mkdir -Path $ProjBuildPath }
  if (!(Test-Path $ProjDistPath))  { mkdir -Path $ProjDistPath }
}

task msbuild {
  & cmd.exe /c  build.bat
}

task compile -description "Build Deliverable zip file" -depends clean, git-history, create-dirs, set-versionAssembly, msbuild {
  $versionNum = Get-Content $ProjVersionPath
  $version = [system.Version]::Parse($versionNum)
  $copyArgs = @{
    path  = @("$ProjTopdir\README.md", $ProjHistoryPath, $ProjVersionPath,
      "CmdletRuusty\bin\Release\Ruusty.ReleaseUtilities.xml",
      "CmdletRuusty\bin\Release\Ruusty.ReleaseUtilities.dll",
      "CmdletRuusty\about_Ruusty.ReleaseUtilities.help.txt"
      ) # TODO
    exclude = @("*.log", "*.html", "*.credential", "*.TempPoint.psd1", "*.TempPoint.ps1", "*.Tests.ps1")
    destination = $ProjBuildPath
    recurse = $true
  }
  Write-Host "Attempting to get deliverables"
  Copy-Item @copyArgs -verbose:$verbose -ErrorAction Stop


  Push-Location $ProjBuildPath;
  Write-Host "Attempting Versioning"
  Ruusty.ReleaseUtilities\set-VersionReadme "$ProjBuildPath/README.md"  $version  $now

#  #Version any Packages
#  $pkgPath = Join-Path $ProjBuildPath "OMS\sql_packages\OMS.PLANNED_OUTAGE.pkb"
#  Ruusty.PSReleaseUtilities\Set-VersionPlSql $pkgPath $version

#  $plsqlVersionPath = Join-Path $ProjBuildPath "990_Version-pon.oms.sql"
#  if (Test-Path $plsqlVersionPath )
#  {
#    Ruusty.PSReleaseUtilities\Set-Token $plsqlVersionPath 'ProductVersion' $versionNum
#  }


  Write-Host "Attempting convert markdown to html"
  import-module -verbose:$verbose md2html; convertto-mdhtml -verbose:$verbose  -recurse

  Write-Host "Attempting to create zip file with '$zipArgs'"

  start-exe $zipExe -ArgumentList $zipArgs -workingdirectory $ProjBuildPath
  Pop-Location;

  Copy-Item "$ProjBuildPath/README.*" $ProjDistPath

}

task compile-nupkg -description "Compile Chocolatey nupkg from nuspec" {
  $versionNum = Get-Content $ProjVersionPath
  Write-Host $("Compiling {0}" -f $ProjNuspecPath)
  exec { & $ChocoExe pack $ProjNuspecPath --version $versionNum }
}


task distribute-nupkg -description "Push nupkg to Chocolatey Feed"{
  $versionNum = Get-Content $ProjVersionPath
  $nupkg = $ExecutionContext.InvokeCommand.ExpandString($ProjNuspecPkgVersionPath)
  Write-Host $("Pushing {0}" -f $nupkg)
  exec { & $ChocoExe  push $nupkg -s $CoreChocoFeed }
}

<#
task distribute -description "Copy deliverables to the Public Delivery Location" {
  $versionNum = Get-Content $ProjVersionPath
  $DeliveryCopyArgs = @{
    path = @("$ProjDistPath/*")
    destination = $ExecutionContext.InvokeCommand.ExpandString($ProjDeliveryPath)
    exclude = @("*.zip")
    Verbose = $verbose
  }
  if (!(Test-Path $DeliveryCopyArgs.Destination)) { mkdir -Path $DeliveryCopyArgs.Destination }
  Copy-Item @DeliveryCopyArgs
  $DestZipPath = $ExecutionContext.InvokeCommand.ExpandString($ProjPackageZipVersionPath)
  Write-Host $DestZipPath
  Copy-Item $ProjPackageZipPath $DestZipPath -verbose:$verbose
  dir $DeliveryCopyArgs.destination
}
#>

task clean -description "Remove all generated files" -depends clean-dirs{

}

task set-version -description "Create the file containing the version" {
  $version = Ruusty.ReleaseUtilities\Get-Version 1 1
  Set-Content $ProjVersionPath $version.ToString()
  Write-Host $("Version:{0}" -f $(Get-Content $ProjVersionPath))
}

task set-versionAssembly -description "version the AssemblyInfo.cs" {
  $versionNum = Get-Content $ProjVersionPath
  $version = [system.Version]::Parse($versionNum)
  Ruusty.ReleaseUtilities\Set-VersionAssembly "CmdletRuusty\Properties\AssemblyInfo.cs" $version
}

task tag-version -description "Create a tag with the version number" {
  $versionNum = Get-Content $ProjVersionPath
  exec { & $GitExe "tag" "V$versionNum" }
}

task Display-version -description "Display the current version" {
  $versionNum = Get-Content $ProjVersionPath
  Write-Host $("Version:{0}" -f $versionNum)
}

task git-revision -description "" {
  exec { & $GitExe "describe" --tag }
}

task git-history -description "Create git history file" {
  exec { & $GitExe "log"  --since="$ProjHistorySinceDate" --pretty=format:"%h - %an, %ai : %s" } | Set-Content $ProjHistoryPath
}

task git-status -description "Stop the build if there are any uncommitted changes" {
  $rv = exec { & $GitExe status --short  --porcelain }
  $rv | write-host

  #Extras
  #exec { & git.exe ls-files --others --exclude-standard }

  if ($rv)
  {
    throw $("Found {0} uncommitted changes" -f ([array]$rv).Count)
  }
}

task show-deliverable {
  $versionNum = Get-Content $ProjVersionPath
  $Dest = $ExecutionContext.InvokeCommand.ExpandString($ProjDeliveryPath)
  $Dest
  & cmd.exe /c explorer.exe $Dest
  dir $Dest
}

task Show-Settings -description "Display the psake configuration properties variables"   {
  Write-Verbose("Verbose is on")
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive | Format-Table -property name, value -autosize | Out-String -Width 2000 | Out-Host
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive | format-list -Expand CoreOnly -property name, value | Out-String -Width 2000 | Out-Host
}


task set-buildList -description "Generate the list of files to go in the zip deliverable"  {
  Push-Location $ProjTopdir
  #get the paths referenced by the Top level sql file
  $FileInZip = Get-BuildList -ProjectName $ProjectName -sqlSpec @("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql") -logsuffix @(".Build.Number", ".git_history.txt") -verbose:$verbose
  Pop-Location
  $FileInZip | sort -Unique | Set-Content $ProjPackageListPath
}

task ? -Description "Helper to display task info" -depends help {
}


task help -Description "Helper to display task info" {
  Invoke-psake -buildfile $me -detaileddocs -nologo
  Invoke-psake -buildfile $me -docs -nologo
}