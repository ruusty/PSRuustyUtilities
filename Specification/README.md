# CmdletRuusty #

<pre style="font-size: .75em;"><code>
Project:        GIS/OMS
Product:        CmdletRuusty
Version:        0.0.0.0
Date:           2017-06-04T22-55
Description:    Specification for the Ruusty Cmdlets and used by Pester Tests.

CHED Services
</code></pre>


<a name="TOC"></a>
# Table of Contents

- [Description](#Description)

<a name="Description"></a>
## Description [^](#TOC) ##

~~~
import-module R:\Projects-Ruusty\PSRuustyReleaseUtilities\CmdletRuusty\bin\Release\Ruusty.ReleaseUtilities.dll
get-module "Ruusty.ReleaseUtilities" | select -expand ExportedCommands
$(get-module Ruusty.ReleaseUtilities).ExportedCommands.Keys |% {get-help $_}
~~~

Cmdlet specifications using *Pester*.

~~~
pester  -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~

- SetVersionReadmeCmdlet
~~~
pester  -testname "SetVersionReadmeCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~
- FindFileUpCmdlet
~~~
pester  -testname "FindFileUpCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~
- GetVersionCmdlet
~~~
pester  -testname "GetVersionCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~ 
- SetVersionAssemblyCmdlet
~~~
pester  -testname "SetVersionAssemblyCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~
- SetVersionModuleCmdlet
~~~
pester  -testname "SetVersionModuleCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~
- SetVersionPlSqlCmdlet
~~~
pester  -testname "SetVersionPlSqlCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~
- SetTokenCmdlet
~~~
pester  -testname "SetTokenCmdlet" -Script @{ Path = './CmdletRuusty.Tests.ps1' }
~~~

Replacing @TITLE@ with "Foo Bar" in  files. 
        
            <token key="TITLE" value="Foo Bar" />
        
~~~        
        Set-Token string[] path, string key, string value
~~~        

