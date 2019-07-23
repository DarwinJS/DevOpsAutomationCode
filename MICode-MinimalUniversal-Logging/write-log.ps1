

# Why and How Blog Post: 
# Windows and Linux Versions: https://github.com/DarwinJS/DevOpsAutomationCode/tree/master/TCPConnectPreflightCheck

#Design Heuristic:
# this is the simpliest, most broadly compatible powershell log function I could devise.
# It is provided because shell scripts are frequently buried at the bottom of a complex stack and getting diagnostic data out can be challenging.
# It also prevents you from being dependent on your tooling users for proper logging implementation by making it a self-contained concern.
# It ensures a date string and that your logging goes to a system location that is subject to log collection
# To implement, update "write-host" statements to "write-logs"
# If you already have logging handled, then the below may unnecessary.
# By using .NET classes directly instead of write-eventlog allows it to work under powershell core on Windows, but not on linux

Function Write-Log ($Msg, $Type='Information', $ID='1') {
  #Defaults to an Information message with EventID 1 - but ID can be specified and type must be one of: Info, Error, Warning, SuccessAudit, FailureAudit
  If ($script:PSCommandPath -ne '' ) { $SourcePathName = $script:PSCommandPath ; $SourceName = split-path -leaf $SourcePathName} else {$SourceName = "Automation Code"; $SourcePathName = "Unknown"}
  Write-Host "[$(Get-date -format 'yyyy-MM-dd HH:mm:ss zzz')] ${Type}: From: $SourcePathName : $Msg"
  If ((test-path variable:iswindows) -AND ($IsWindows)) {
  $applog = New-Object -TypeName System.Diagnostics.EventLog -argumentlist Application
  $applog.Source="$SourceName"
  $applog.WriteEntry("From: $SourcePathName : $Msg", $Type, $ID) }
  #eventcreate.exe /L Application /SO "$SourceName" /T "$Type" /ID $ID /D "From: $SourcePathName : $Msg"
} 