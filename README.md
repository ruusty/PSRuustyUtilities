# Ruusty.ReleaseUtilities #

~~~
Project:        Ruusty Release Tools
Product:        PSRuustyUtilities
Version:        4.3
Date:           2017-08-16
Description:    Powershell binary cmdlet contains tools for building releases.
~~~


<a name="TOC"></a>
# Table of Contents

- [Description](#Description)

<a name="Description"></a>
## Description [&uarr;](#TOC) ##


Chocolatey Package **PSRuustyUtilities**  installs Powershell binary module `Ruusty.ReleaseUtilities`

To get help and examples

~~~
import-module Ruusty.ReleaseUtilities
get-module "Ruusty.ReleaseUtilities" | select -expand ExportedCommands
$(get-module Ruusty.ReleaseUtilities).ExportedCommands.Keys |% {get-help $_}
~~~

