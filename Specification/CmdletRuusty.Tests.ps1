$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

<#
Powershell

Invoke-Pester -testname "StartExeCmdlet"      -Script @{ Path = './CmdletRuusty.Tests.ps1' }
pester  -testname "StartExeCmdlet"          -Script @{ Path = './CmdletRuusty.Tests.ps1' }

invoke-pester
  get-module
  get-module "Ruusty.Version" | select -expand ExportedCommands
  $(get-module "Ruusty.PSVersion").ExportedCommands.Keys
  #$(get-module CmdletRuusty).ExportedCommands.Keys | % { get-help $_ }

$mod = Get-Module -FullyQualifiedName @{ModuleName="Ruusty.PSVersion";ModuleVersion="1.0.1.0"}

$mod.ExportedCommands["Get-Version"]
& $mod.ExportedCommands["Get-Version"]
pester -Script

pester  -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>


<#
Ensure all expect modules exported
#>

<#
pester -testname "GetVersionCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "GetVersionCmdlet" {
  It "Should be of type Version" {
    #$mod = Get-Module -FullyQualifiedName @{ ModuleName = "Ruusty.ReleaseUtilities"; ModuleVersion = "1.0.1.0" }
    $mod = Get-Module -FullyQualifiedName @{ ModuleName = "Ruusty.ReleaseUtilities"; MaximumVersion = "5.0.0.0" }

    $v = & $mod.ExportedCommands["Get-Version"]
    Write-Host  $v
    $v | should BeOfType System.Version
  }

  It "Should be of type Version" {
    $v = Ruusty.ReleaseUtilities\Get-Version
    Write-Host  $v
    $v | should BeOfType System.Version
  }

  It "Should be of 0.0" {
    $v = Ruusty.ReleaseUtilities\Get-Version
    Write-Host  $v
    $v.Major | Should BeExactly 0
    $v.Minor | Should BeExactly 0
  }

  It "Should be of 4.3" {
    $v = Ruusty.ReleaseUtilities\Get-Version -major 4 -minor 3
    Write-Host  $v
    $v.Major | Should BeExactly 4
    $v.Minor | Should BeExactly 3
  }

  It "Should be of 4.3" {
    $v = Ruusty.ReleaseUtilities\Get-Version -major 4 -minor 3 -StartDate $(get-date)
    Write-Host  $v
    $v.Major | Should BeExactly 4
    $v.Minor | Should BeExactly 3
    $v.build | Should beExactly $($(get-date).Day)
  }
}

<#
pester -testname "FindFileUpCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "FindFileUpCmdlet" {

  It "Should throw when no name" {
    { Ruusty.ReleaseUtilities\Find-FileUp  $(Get-Location) $null } | Should Throw;
  }
  It "Should throw when empty Name" {
    { Ruusty.ReleaseUtilities\Find-FileUp  $(Get-Location) "" } | Should Throw;
  }
  It "Should throw when file not found" {
    { Ruusty.ReleaseUtilities\Find-FileUp  "!!Notfound!!.xml" } | Should Throw;
  }
  It "Should not throw when valid args" {
    { Ruusty.ReleaseUtilities\Find-FileUp -StartDirectory $(Get-Location)  -name "CmdletRuusty.sln" } | Should Not Throw;
  }

  It "Should find lower GisOms.Chocolatey.properties.pca16128.xml" {
    $dir = Join-Path $PSScriptRoot "FindFileUpCmdlet\Folder01\Folder02\Folder03"
    $foundFile = Ruusty.ReleaseUtilities\Find-FileUp -name "GisOms.Chocolatey.properties.pca16128.xml" -StartDirectory $dir
    Write-Host $foundFile
    $foundFile | Should Exist
  }

  It "Should find upper GisOms.Chocolatey.properties.pca16128.xml" {
    $dir = Join-Path $PSScriptRoot "FindFileUpCmdlet\Folder01\Folder02"
    $foundFile = Ruusty.ReleaseUtilities\Find-FileUp -name "GisOms.Chocolatey.properties.pca16128.xml" -StartDirectory $dir
    Write-Host $foundFile
    $foundFile | Should Exist
  }
}

<#
pester -testname "SetVersionReadmeCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "SetVersionReadmeCmdlet"{

  #region setup $dependencies
  $SpecificationDir = join-path $PSScriptRoot "SetVersionReadmeCmdlet"
  Push-Location $SpecificationDir
  $File01 = Join-Path $SpecificationDir "README-Large.md"
  $manyFiles = "$SpecificationDir\*.md"
  #endregion

  It "Should throw when file not found" {
    { Ruusty.ReleaseUtilities\Set-VersionReadme "file-not-found.zzz" } | Should throw;
  }

  It "Should Default to now Datestamp and 0.0.0.0"{
    $testDate =[DateTime]::Now.ToString("yyyy-MM-ddTHH-mm")
    Ruusty.ReleaseUtilities\Set-VersionReadme $File01
    $File01 | Should contain "0.0.0.0"
    $File01 | Should contain $testDate;
  }


  It "Should Version many files"{
    $files = Resolve-Path -Path $(Join-Path $SpecificationDir "README-*.md")
    Ruusty.ReleaseUtilities\Set-VersionReadme $files -verbose
    $files | Should contain "0.0.0.0"
    $files | Should contain $testDate;
  }

  It "Should Version many files with version parameter"{
    $files = Resolve-Path -Path $(Join-Path $SpecificationDir "README-*.md")
    $v = Ruusty.ReleaseUtilities\Get-Version -major 10 -minor 12
    Ruusty.ReleaseUtilities\Set-VersionReadme $files -verbose -version $v
    $files | Should contain $v.ToString()
    $files | Should contain $testDate;
  }

  It "Should Version many files with version parameter in pipeline"{
    $files = Resolve-Path -Path $(Join-Path $SpecificationDir "README-*.md")
    $v = Ruusty.ReleaseUtilities\Get-Version -major 10 -minor 12
    $files | Ruusty.ReleaseUtilities\Set-VersionReadme  -verbose -version $v
    $files | Should contain $v.ToString()
    $files | Should contain $testDate;
  }

  It "Should Version many files from get-childitem with version parameter in pipeline"{
    $fileinfo = Get-ChildItem -Path $SpecificationDir -Recurse -Filter *.md
    $files = $fileinfo | % { $_.FullName }
    $v = Ruusty.ReleaseUtilities\Get-Version -major 10 -minor 12
    $files | Ruusty.ReleaseUtilities\Set-VersionReadme -verbose -version $v
    $files | Should contain $v.ToString()
    $files | Should contain $testDate;
  }


  BeforeEach {
    & git checkout -- "$manyFiles" "Folder2\*.md"
  }
   AfterEach {
    & git checkout -- "$manyFiles" "Folder2\*.md"
  }
}

<#
pester -testname "SetVersionAssemblyCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "SetVersionAssemblyCmdlet" {

  #region setup $dependencies
  $SpecificationDir = join-path $PSScriptRoot "SetVersionAssemblyCmdlet"
  Push-Location $SpecificationDir
  $File01 = Join-Path $SpecificationDir "AssemblyInfo.cs"

  It "Should throw when file not found" {
    { Ruusty.ReleaseUtilities\Set-VersionAssembly "file-not-found.zzz" } | Should throw;
  }

  It "Should default to 0.0.0.0 on single file" {
    $versionNum="0.0.0.0"
    Ruusty.ReleaseUtilities\Set-VersionAssembly $File01 -verbose
    $File01 | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
    $File01 | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
  }

  It "Should set to version to '1.2.3.4 on single file'" {
    $versionNum = '1.2.3.4'
    $version = [system.Version]::Parse($versionNum)
    Ruusty.ReleaseUtilities\Set-VersionAssembly $File01 $version -verbose
    $File01 | Should contain 'assembly: AssemblyVersion\("1.2.3.4"\)'
    $File01 | Should contain 'assembly: AssemblyFileVersion\("1.2.3.4"\)'
  }

  It "Should Version multiple files" {
    $versionNum = '1.2.3.5'
    $version = [system.Version]::Parse($versionNum)
    $files = Get-ChildItem -Path $DestDir -Filter "assembly*.cs" | %{ $_.FullName }
    $files |%{  write-host $_ }
    { Ruusty.ReleaseUtilities\Set-VersionAssembly -Path $files -version $version  -verbose} | Should not throw;
    $files | Should contain $versionNum
    $files | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
    $files | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
  }

  It "Should Version many Assembly files in pipeline" {
    $versionNum = '1.2.3.6'
    $version = [system.Version]::Parse($versionNum)
    $files = Get-ChildItem -Path $DestDir -Recurse -Filter "assembly*.cs" | %{ $_.FullName }
    $files | %{ write-host $_ }
    { $files | Ruusty.ReleaseUtilities\Set-VersionAssembly -version $version -verbose } | Should not throw;
    $files | Should contain $versionNum
    $files | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
    $files | Should contain "assembly: AssemblyFileVersion\(`"$versionNum`"\)"
  }

  It "Should not change ASCII encoding" {
    $versionNum = '0.0.0.0'
    $version = [system.Version]::Parse($versionNum)
    $files = Join-Path $SpecificationDir "AssemblyInfo-ASCII.cs"
    $diff = $(& git diff  $files)
    $diff | Should BeNullOrEmpty
  }


  It "Should not change UTF-8 encoding" {
    $versionNum = '0.0.0.0'
    $version = [system.Version]::Parse($versionNum)
    $files = Join-Path $SpecificationDir "AssemblyInfo-UTF-8.cs"
    $diff = $(& git diff  $files)
    $diff | Should BeNullOrEmpty
  }

  BeforeEach {
    & git checkout -- "*.cs" "project?\**\*.cs"
  }
}

<#
pester -testname "SetVersionModuleCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "SetVersionModuleCmdlet"  {
  $SpecificationDir = join-path $PSScriptRoot "SetVersionModuleCmdlet"
  $file = $(Join-Path $SpecificationDir "md2html.psd1")
  $versionNum = '1.2.3.4'
  $versionNumEncoding = '0.0.0.0'

  It "Should throw when file not found" {
    { Ruusty.ReleaseUtilities\Set-VersionModule "file-not-found.zzz" } | Should throw;
  }

  It "Should change the Module version only to 0.0.0.0"{
    Ruusty.ReleaseUtilities\Set-VersionModule $file
    $file | Should contain 	"^\s+ModuleVersion\s+=\s+'0.0.0.0'"
  }

  It "Should change the Module version only to $versionNum "{
    $version = [system.Version]::Parse($versionNum)
    Ruusty.ReleaseUtilities\Set-VersionModule $file $version
    $file | Should contain 	"^\s+ModuleVersion\s+=\s+'1.2.3.4'"
  }

  It "Should not change ASCII encoding"{
    $file =  $(Join-Path $SpecificationDir "md2html-ASCII.psd1")
    $version = [system.Version]::Parse($versionNumEncoding)
    Ruusty.ReleaseUtilities\Set-VersionModule $file $version
    $file | Should contain 	"^\s+ModuleVersion\s+=\s+\'$versionNumEncoding\'"
    $diff = $(& git diff  $file)
    $diff | Should BeNullOrEmpty
  }

  It "Should not change UTF-8 encoding"{
    $file = $(Join-Path $SpecificationDir "md2html-UTF-8.psd1")
    $version = [system.Version]::Parse($versionNumEncoding)
    Ruusty.ReleaseUtilities\Set-VersionModule $file $version
    $file | Should contain 	"^\s+ModuleVersion\s+=\s+\'$versionNumEncoding\'"
    $diff = $(& git diff  $file)
    $diff | Should BeNullOrEmpty
  }


  BeforeEach {
    & git checkout -- $file
  }
}

<#
pester -testname "SetVersionPlSqlCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "SetVersionPlSqlCmdlet" {
  $SpecificationDir = join-path $PSScriptRoot "SetVersionPlSqlCmdlet"
  $file01 = $(Join-Path $SpecificationDir "SCHEMA.PLANNED_PROCESSOR.pkb")
  $file02 = $(Join-Path $SpecificationDir "SCHEMA.PLANNED_PROCESSOR - Good.pkb")
  $ASCIIFile = $(Join-Path $SpecificationDir "ASCII.txt")
  $UTF8BomFile = $(Join-Path $SpecificationDir "UTF8-BOM.txt")
  $UTF8File = $(Join-Path $SpecificationDir  "UTF8.txt")
  $versionNum = '1.2.3.4'

  It "Should not Change Not Found version Octet  "{
      { Ruusty.ReleaseUtilities\Set-VersionPlSql $file01 -verbose }  | Should Not Throw;
      $file01 | Should Contain "'4.1.mmmm.nnnn';"
    }

  It "Should be no change as no match"{
      { Ruusty.ReleaseUtilities\Set-VersionPlSql  $file01 -verbose } | Should Not Throw;
    $diffs =  & git.exe diff -- $file01
    $diffs | Should BeNullOrEmpty;
    }

  It "should  set version to 0.0.0.0" {
    Ruusty.ReleaseUtilities\Set-VersionPlSql  $file02 -verbose
    $file02 | Should Contain "'0.0.0.0'"
  }


  It "should set version to $versionNum" {
    Ruusty.ReleaseUtilities\Set-VersionPlSql  $file02 $([system.Version]::Parse($versionNum)) -verbose
    $file02 | Should Contain "`'${versionNum}`'"
    }

  It "should set version to $versionNum" {
    Ruusty.ReleaseUtilities\Set-VersionPlSql  $file02 $([system.Version]::Parse($versionNum)) -verbose
    $file02 | Should contain 	"'1.2.3.4'"
  }

  It "Should not change encoding from ASCII"{
    Ruusty.ReleaseUtilities\Set-VersionPlSql $ASCIIFile $([system.Version]::Parse($versionNum)) -verbose
    $diffs = & git.exe diff -- $ASCIIFile
    $diffs | Should BeNullOrEmpty;
  }

  It "Should not change encoding from UTF8"{
    Ruusty.ReleaseUtilities\Set-VersionPlSql $UTF8File $([system.Version]::Parse($versionNum)) -verbose
    $diffs = & git.exe diff -- $UTF8File
    $diffs | Should BeNullOrEmpty;
  }

  It "Should not change encoding from UTF8-BOM"{
    Ruusty.ReleaseUtilities\Set-VersionPlSql $UTF8BomFile $([system.Version]::Parse($versionNum)) -verbose
    $diffs = & git.exe diff -- $UTF8BomFile
    $diffs | Should BeNullOrEmpty;
  }


  BeforeEach {
    & git checkout -- $file01  $file02 $ASCIIFile $UTF8File  $UTF8BomFile
  }
}

<#
pester -testname "SetTokenCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
Describe "SetTokenCmdlet"{
  #region setup $dependencies
  $SpecificationDir = $(join-path $PSScriptRoot "SetTokenCmdlet")
  $File01 = $(Join-Path $SpecificationDir "File01.txt")
  $File02 = $(Join-Path $SpecificationDir "README.md")
  $File03 = $(Join-Path $SpecificationDir "README-ASCII.md")
  #endregion


  It "Should be Case-Sensitive"{
    { Ruusty.ReleaseUtilities\Set-Token  $File01 "title" "value" } | Should Not Throw;
    $File01 | Should not Contain "value"
    $File01 | Should  Contain "@TITLE@"
  }

      It "Should expand @TITLE@ to value"{
        { Ruusty.ReleaseUtilities\Set-Token  $File01 "TITLE" "value" } | Should Not Throw;
        $File01 | Should Contain "value"
        $File01 | Should Not Contain "@TITLE@"
      }

      It "Should expand @SDLC@ to value multiple times"{
        { Ruusty.ReleaseUtilities\Set-Token  $File02 "SDLC" "production" } | Should Not Throw;
        $File02 | Should Contain "production"
        $File02 | Should Not Contain "@SDLC@"
      }

      It "Should expand @SDLC@ to value multiple times and not change encoding"{
        { Ruusty.ReleaseUtilities\Set-Token  $File03 "SDLC" "@SDLC@" } | Should Not Throw;
        $File03 | Should not Contain "production"
        $File03 | Should Contain "@SDLC@"
        $diffs = & git.exe diff -- $File03
        $diffs | Should BeNullOrEmpty;
      }


      BeforeEach {
        & git checkout -- $File01 $File02
      }

    }

<#
pester -testname "StartExeCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
#>
    Describe "StartExeCmdlet" {
      #region setup $dependencies
      $SpecificationDir = $(join-path $PSScriptRoot "StartExeCmdlet")

      Push-Location $SpecificationDir


      function New-TempDir
      {
        $Path = "$env:Temp\$([System.IO.Path]::GetRandomFileName())"
        Write-Verbose "Creating temp dir: $Path"
        return [string] (mkdir $Path)
      }
      $logFile = Join-Path $(New-TempDir) "rusty.log"
      Write-Host $logFile
      #endregion
      It "Should sleep for 2 seconds" {
        { Ruusty.ReleaseUtilities\Start-Exe -FilePath "sleep.exe" -ArgumentList 2 } | Should Not Throw;
      }

      It "Should Start ls " {
        { Ruusty.ReleaseUtilities\Start-Exe -FilePath "ls.exe" -ArgumentList "-l" } | Should Not Throw;
      }


      It "Should Start ls and write to log file" {
        { Ruusty.ReleaseUtilities\Start-Exe -FilePath "ls.exe" -ArgumentList "-l" -LogPath $logFile } | Should Not Throw;
        $logFile | should exist;
      }

      It "Should write to log file" {
        { Ruusty.ReleaseUtilities\Start-Exe -FilePath "wc.exe" -ArgumentList "-l -w ipsum-lorem.txt" -LogPath $logFile -verbose -WorkingDirectory $SpecificationDir} | Should Not Throw;
        $logFile | should exist;
        $logFile | should contain "11  443 ipsum-lorem.txt";
      }


      It "Should write to log file in working directory" {
        { Ruusty.ReleaseUtilities\Start-Exe -FilePath "wc.exe" -ArgumentList @("-l","-w","ipsum-lorem.txt") -LogPath $logFile -verbose -WorkingDirectory $SpecificationDir } | Should Not Throw;
        $logFile | should exist;
        $logFile | should contain "11  443 ipsum-lorem.txt";
      }

      BeforeEach {
        if (Test-Path $logFile) { rm $logFile -ErrorAction SilentlyContinue }
      }

    }
