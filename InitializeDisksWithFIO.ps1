<#
.SYNOPSIS
  Initializes (full read of all bytes) AWS EBS volumes using FIO (File IO Utility).
  See this post for full details on why this code is helpful: https://cloudywindows.io/post/fully-automated-on-demand-ebs-initialization-in-both-bash-for-linux-and-powershell-for-windows/
.DESCRIPTION
  CloudyWindows.io DevOps Automation: https://github.com/DarwinJS/DevOpsAutomationCode
  Why and How Blog Post: https://cloudywindows.io/post/culling-dead-computer-records-from-ad-with-a-scheduled-powershell-oneliner/
  invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:public\InitializeDisksWithFIO.ps1 ; & $env:public\InitializeDisksWithFIO.ps1
  invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:public\InitializeDisksWithFIO.ps1 ; & $env:public\InitializeDisksWithFIO.ps1 -repeatintervalminutes 1
.COMPONENT
   CloudyWindows.io
.ROLE
  Provisioning Automation
.PARAMETER DeviceIDsToInitialize
  Specifies list of semi-colon seperated number ids of local Devices to initialize.  Devices appear in HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum.
  Not specifying this value or specifying 'All' results in attempting to enumerate and initialize all devices on the system.
  Generally deviceid 0 will be the boot drive - but that is not guaranteed.
  You do not need to initialize EBS volumes that were created as part of an instance launch - they have full performance without initializing.
.PARAMETER Version
  Emit version and exit.
.PARAMETER Unschedule
  Remove InitializeDisksWithFIO.ps1 scheduled task and script.
.PARAMETER RepeatIntervalMinutes
  schedule to run every x minutes.  Range: 1 to 59.
  Use for: (a) synchcronous (parallel) execution, (b) reboot resilience, (c) run after other automation complete (max 59 mins).
  RepeatIntervalMinutes will also update existing schedule if already scheduled.
  RepeatIntervalMinutes also pushes source script version if you are not rerunning the local script (upgrades or downgrades to source version)
  Once device initialization is successfully accomplished, script removes itself from scheduled tasks and from the system.
  When RepeatIntervalMinutes is not used, the command runs asyncrhonously.
.PARAMETER NiceLevel
  CPU throttling supported natively by FIO.  Range is -20 through 19.
  On Windows, values less than -15 set the process class to “High”; -1 through -15 set “Above Normal”; 
  1 through 15 “Below Normal”; and above 15 “Idle” priority class
.PARAMETER InvokedFromSchedule
  Only used internally for a scheduled run of code to self-identify as having launched from a scheduled task.
.EXAMPLE
  invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:public\InitializeDisksWithFIO.ps1 ; & $env:public\InitializeDisksWithFIO.ps1
  
  Download and run directly from github with no parameters.
.EXAMPLE
  invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:public\InitializeDisksWithFIO.ps1 ; & $env:public\InitializeDisksWithFIO.ps1 -DeviceIDsToInitialize '1;3'
  
  Download and run directly from github WITH parameters.
.EXAMPLE
  invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:public\InitializeDisksWithFIO.ps1 ; & $env:public\InitializeDisksWithFIO.ps1 -RepeatIntervalMinutes 1

  If you wish to direct download and schedule the script, you must use the above command line as the method of downloading.
.EXAMPLE
  InitializeDisksWithFIO.ps1
  
  Initialize all local, writable, non-removable disk devices immediately
.EXAMPLE
  InitializeDisksWithFIO.ps1 -RepeatIntervalMinutes5 # schedule every 5 minutes to initialize all local, writable, non-removable disk devices
.EXAMPLE
  InitializeDisksWithFIO.ps1 -DeviceIDsToInitialize '1;4'
  
  Initialize specified device IDs
.EXAMPLE
  InitializeDisksWithFIO.ps1 -NiceLevel 5 
  
  Use specified nice cpu priority to initialize all local, writable, non-removable disk devices.
.EXAMPLE
  InitializeDisksWithFIO.ps1 -Version 
  
  Emit only script version (good for comparing whether local version is older than latest online version)
.EXAMPLE
  If ([version]($(invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1' -outfile $env:temp\InitializeDisksWithFIO.ps1 ; & $env:temp\InitializeDisksWithFIO.ps1 -version)) -gt [version]($(& $env:public\InitializeDisksWithFIO.ps1 -version))) {write-host "INFO: Running an old version"}

  Check if script is up to date with github version.
.NOTES

  Features:
    Deploying Solution
    - oneliner to download from web and run
    - complete offline operation by copying script and installing or copying fio to image
    - defaults to prefer using fio from path or current directory
    - on the fly install of FIO
    - schedule recurrent scheduled task for (only a single instance ever runs):
      - reboot resilience - scheduled task is recurrent each x minutes and self deletes after 
        successful completion
      - future run - up to 59 minutes away (e.g. allow other automation to complete) 
      - parallel run - allow automation to continue (set -RepeatIntervalMinutes 1) 

    Running
    - initialize multiple devices in parallel (default)
    - CPU throttling (nice)
    - skips non-existence devices
    - takes device list (use -DeviceIDsToInitialize)
    - if no device list, enumerates all local, writable, non-removable devices 
      (override incorrect device detection by specifying device list)
    - emits bare version (can be used to update or warn when a local copy is older than the latest online version)

    Completion and Cleanup (when fio runs to completion)
    - saves fio output report
    - marks initialization done - which preempts further runs and scheduling until done file is removed
    - removes scheduled task and copy of script

    Tested On
    - PowerShell 4 (Server 2012 R2)
    - PowerShell 5.1
    - PowerShell Core 6.0.1
#>

Param (
  [String]$DeviceIDsToInitialize,
  [Switch]$Version,
  [Switch]$Unschedule,
  [ValidateRange(1,59)] 
  [Int]$RepeatIntervalMinutes,
  [ValidateRange(-20,19)] 
  [String]$NiceLevel,
  [Switch]$InvokedFromSchedule
  )
  
  #update to grab latest tag?
  $SubFolder = 'fio'
  $EXE = "fio.exe"
  <# Static Method
  $Release = 'fio-3.1-x64'
  $URL = "https://www.bluestop.org/files/fio/releases/$Release.zip"
  $LastSegment = (("$URL") -split '/') | select -last 1
  #>
  $LastSegment = (iwr https://www.bluestop.org/files/fio/releases).links.href | where {$_ -match 'fio-.*-x64.zip'} | sort | select -last 1
  $Release = [io.path]::GetFileNameWithoutExtension("$LastSegment")
  $URL = "https://www.bluestop.org/files/fio/releases/$LastSegment"


$SharedWritableLocation="$env:public"
$env:path += ";$pwd;$SharedWritableLocation"
$SCRIPT_VERSION=1.8
$SCRIPTNETLOCATION='https://raw.githubusercontent.com/DarwinJS/DevOpsAutomationCode/master/InitializeDisksWithFIO.ps1'
$REPORTFILE="$SharedWritableLocation/initializediskswithfioreport"
$DONEMARKERFILE="$SharedWritableLocation/initializediskswithfio.done"
$GITHUBURL="https://github.com/DarwinJS/DevOpsAutomationCode"

If ($Version)
{
  Write-Output "$SCRIPT_VERSION"
  Exit 0
}

$Banner = @"

*********************************************************
InitializeDisksWithFIO.sh Version: ${SCRIPT_VERSION}
Running From: $($MyInvocation.MyCommand.Path)
Updates and information: ${GITHUBURL}

"@

Write-Host $Banner
Function Remove-SchedScriptIfItExists {
  If (Test-Path "$SharedWritableLocation\InitializeDisksWithFIO.ps1")
  {Remove-Item "$SharedWritableLocation\InitializeDisksWithFIO.ps1" -Force -ErrorAction SilentlyContinue}
}

Function Remove-SchedJobIfItExists {
& schtasks.exe /delete /f /tn "InitializeDisksWithFIO.ps1"
}

If ($Unschedule)
{
  Write-Host "Attempting to remove schedule and script and then exit."
  Remove-SchedJobIfItExists
  Remove-SchedScriptIfItExists
  exit 0
}

#If fio is found on the path or in the same folder as the script, it is used, otherwise it is automatically downloaded to the sharedwritablelocation and used from there.
$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!$FIOPATHNAME -OR !(Test-Path "$FIOPATHNAME"))
{
  Write-Host "Fetching `"$URL`" to `"$SharedWritableLocation`""
  Invoke-WebRequest -Uri "$URL" -outfile "$SharedWritableLocation\$LastSegment"

  If ($LastSegment.endswith(".zip"))
  {
    If (Test-Path "$SharedWritableLocation\$Release") {remove-item "$SharedWritableLocation\$Release" -Force -Recurse}
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("$SharedWritableLocation\$LastSegment","$SharedWritableLocation")
  }
  copy-item "$SharedWritableLocation\$Release\fio.exe" "$SharedWritableLocation" -Force
  Remove-Item "$SharedWritableLocation\$Release" -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item "$SharedWritableLocation\$LastSegment" -Recurse -Force -ErrorAction SilentlyContinue
}

$FIOPATHNAME="$((Get-Command fio.exe -ErrorAction SilentlyContinue).Source)"
If (!$FIOPATHNAME -OR !(Test-Path "$FIOPATHNAME"))
{ 
  Throw "Could not find, nor install fio.exe"
}

#If PhysicalDevicesToInitialize is unspecified or "All" then enumerate all devices
If ((!(Test-Path variable:DeviceIDsToInitialize)) -OR ($DeviceIDsToInitialize -ieq 'All') -OR ($DeviceIDsToInitialize -ieq ''))
{
  Write-Host "Enumerating all local, writable, non-removable devices"
  $PhysicalDriveEnumList = 0..$((get-itemproperty HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum | Select -ExpandProperty Count)-1)
}
Elseif ($DeviceIDsToInitialize -ne '')
{
  $PhysicalDriveEnumList = [int[]]($DeviceIDsToInitialize -split ';')
}

$DeviceIDTempList = @()
ForEach ($DeviceID in $PhysicalDriveEnumList)
{
  Write-host "Validating $DeviceID..."
  if ([bool](Get-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Services\disk\Enum\" -ErrorAction SilentlyContinue | Select-Object -Expand $DeviceID -ErrorAction SilentlyContinue))
  {
    $DeviceIDTempList += $DeviceID
  }
  Else 
  {
     Write-Warning "Specified device `"${DeviceID}`" does not exist, skipping..." 
  }
}
$PhysicalDriveEnumList = $DeviceIDTempList

#Only process if we end up with a value for PhysicalDriveEnumList
If (Test-Path variable:PhysicalDriveEnumList)
{
  Write-Host "Devices that will be initialized: $($PhysicalDriveEnumList -join ',')"
  if ($NiceLevel)
  { 
    $nicecmd="--nice=${nicelevel}"
  }
  Foreach ($DriveEnum in $PhysicalDriveEnumList)
  {
    $command += " --filename=\\.\PHYSICALDRIVE$DriveEnum ${nicecmd} --rw=read --bs=128k --iodepth=32 --ioengine=windowsaio --direct=1 --name=volume-initialize-$DriveEnum  --output ${REPORTFILE}-device-$DriveEnum.txt"
  }
}
Else
{
  Throw "Was not able to determine a list of devices to initialize, exiting..."
}

write-host "`$command to use is $command"

if (Test-Path "${DONEMARKERFILE}")
{
  Write-Host "WARNING: Presence of `"${DONEMARKERFILE}`" indicates FIO has completed its run on this system, doing nothing."
  Write-Host  "INFO: `"${DONEMARKERFILE}`" would need to be removed to either run or schedule again."
  #Handle condition where a manual run completed initialization before the scheduled task
  Remove-SchedJobIfItExists
  Remove-SchedScriptIfItExists
  exit 0
}

if ($RepeatIntervalMinutes -ge 1)
{
  Write-Host "SCHEDULING: Initializing the EBS volume(s) ${DriveEnum} ..."
  Write-Host "SCHEDULING: command: '$command' for every ${RepeatIntervalMinutes} minutes until all initializations complete."
  $ScheduledScriptPathname = "$SharedWritableLocation\$(($SCRIPTNETLOCATION -split '/') | select -last 1)"
  if ($script:myinvocation.MyCommand.path -ieq $ScheduledScriptPathname)
  {
    Write-Host "Already running from schedule location"
  }
  Else
  {
    Write-Host "Copying `"$($script:myinvocation.MyCommand.path)`" to `"$ScheduledScriptPathname`""
    Copy-item "$($script:myinvocation.MyCommand.path)" "$ScheduledScriptPathname" -force
  }

  Remove-SchedJobIfItExists #In case we are updating an existing job
  Write-Host "Adding scheduled job"
  $PSBoundParameters.keys | where {$_ -ine 'InvokedFromSchedule'} | where {$_ -ine 'RepeatIntervalMinutes'} | foreach {$arglist += "-$_ $($PSboundparameters.item("$_")) "}
  If ($arglist -imatch 'True') {$arglist = $arglist.replace('True','')}
  $arglist += ' -InvokedFromSchedule'

  $ScheduledJobExecutionString = "powershell.exe -file $ScheduledScriptPathname $arglist"

  Write-Host "Scheduling: $ScheduledJobExecutionString"

  schtasks.exe /create /sc MINUTE /MO $RepeatIntervalMinutes /tn "InitializeDisksWithFIO.ps1" /ru SYSTEM /tr "$ScheduledJobExecutionString"
  exit 0
}
else
{
  If ((Get-Process fio -ErrorAction SilentlyContinue).count -lt 1)
  {
  Write-Host "Running FIO now..."
  # NOTE having one letter of the regex square bracketed prevents grep from finding itself, otherwise it needs to be > 1
  if ((get-process fio -EA SilentlyContinue).count -gt 0)
  {
    Write-Host "fio is already running, exiting..."
    exit 0
  }
  Write-Host "running command: '$FIOPATHNAME $command'"
  Start-Process -Wait -NoNewWindow "$FIOPATHNAME" -ArgumentList "${command}" 
  If ($? -lt 1)
  {
    Write-Host "EBS volume(s) ${DriveEnum} completed initialization, marking as done and removing scheduled task if it was setup."
    Write-Host "INFO: ${DONEMARKERFILE} would need to be removed to either run or schedule again."
    Set-content "$(get-date)" -path "${DONEMARKERFILE}"
    Remove-SchedJobIfItExists
    Remove-SchedScriptIfItExists
  }
  else
  {
    Write-Host "fio did not complete successfully."
  }
  }
  else 
  {
    Write-Host "fio is already running, self-preempting"
    exit 0  
  }
}
