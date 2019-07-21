
#  See this post for full details on why this code is helpful: https://cloudywindows.io/post/no-7zip-allowed-extracting-oracles-gzipped-java-tarball-on-windows-to-create-an-isolated-zero-footprint-java-install-for-cis-cat-pro/

#This code should work on PowerShell 2 and later
#Acquire and unzip the nupkg file containing the assembly
invoke-webrequest -uri 'https://github.com/icsharpcode/SharpZipLib/releases/download/v1.1.0/SharpZipLib.1.1.0.nupkg' -outfile "$PWD/SharpZipLib.1.1.0.nupkg"
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory("$PWD/SharpZipLib.1.1.0.nupkg","$PWD")

Write-host "Untaring Java..."
#Using the net45 version because that is the most likely to be preinstalled for my case, but check other folders under "lib" for other .NET serializations
Add-Type -Path "$PWD\lib\net45\ICSharpCode.SharpZipLib.dll"
#Downloading Java is intense, here are some ideas: https://stackoverflow.com/questions/24430141/downloading-jdk-using-powershell
$gzippedtarball = [IO.File]::OpenRead("$PWD\jre-8u212-windows-x64.tar.gz")
$inStream=New-Object -TypeName ICSharpCode.SharpZipLib.GZip.GZipInputStream $gzippedtarball
$tarIn = New-Object -TypeName ICSharpCode.SharpZipLib.Tar.TarInputStream $inStream
$archive = [ICSharpCode.SharpZipLib.Tar.TarArchive]::CreateInputTarArchive($tarIn)
$archive.ExtractContents($PWD)
#Set JRE Home and add the JRE Bin folder to the path of the current process (the next two lines could also be written to script to allow quick setup of the isolated version from other scripts)
$env:JRE_HOME="$PWD\jre1.8.0_212"
$env:PATH="$env:JRE_HOME\bin;$env:PATH"