# PSRuustyReleaseUtilities #

~~~
Project:        Ruusty Tools
Product:        PSRuustyUtilities
Version:        4.3
Date:           2017-08-16
Description:    PSRuustyUtilities
~~~


<a name="TOC"></a>
# Table of Contents

- [Description](#Description)

<a name="Description"></a>
## Description [&uarr;](#TOC) ##


Chocolatey Package **PSRuustyUtilities** which installs Powershell binary module 
`Ruusty.ReleaseUtilities`

~~~
Import-module Ruusty.Utilities
get-module "Ruusty.Utilities" | select -expand ExportedCommands
$(get-module Ruusty.Utilities).ExportedCommands.Keys |% {get-help $_}

~~~


