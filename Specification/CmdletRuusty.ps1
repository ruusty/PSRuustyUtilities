<#
Load the Cmdlet binary
#>function ImportBinaryModule {
  Import-Module -Name $(join-path $PSScriptRoot "..\CmdletRuusty\bin\release\Ruusty.ReleaseUtilities.dll") -Force -Verbose
  #get-module
  #get-module "Ruusty.PSReleaseUtilities" | select -expand ExportedCommands
  #$(get-module "Ruusty.PSReleaseUtilities").ExportedCommands.Keys
}
ImportBinaryModule
