setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\VsMSBuildCmd.bat"
msbuild CmdletRuusty.sln /t:CmdletRuusty:Clean;CmdletRuusty:Rebuild /p:Configuration=Release /p:Platform="Any CPU"
timeout /t 5
endlocal
