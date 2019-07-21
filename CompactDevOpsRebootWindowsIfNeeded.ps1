
<#
See this post for full details on why this code is helpful: https://cloudywindows.io/post/super-compact-devops-ish-pending-reboot-test-for-the-rebootiest-operating-system-in-the-cloud/

This code is a compact (small enough to be put in the script you need to use it within or inline in orchestration / IaC), DevOps-ish version of Get-PendingReboot.
For compactness some sacrifices were made - it does not detect SCCM reboots and does not work remotely
On the plus side it detects reboots pending from Windows feature install / uninstall operations
It uses "shutdown.exe" because Restart-Computer frequently causes bad terminations of whatever called this.

#>

Function Test-PendingReboot
{
  Return ([bool]((get-itemproperty "hklm:SYSTEM\CurrentControlSet\Control\Session Manager").RebootPending) -OR 
  [bool]((get-itemproperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").RebootRequired) -OR 
  [bool]((get-itemproperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager").PendingFileRenameOperations) -OR 
  #WindowsFeature install or uninstall has a pending reboot:
  ((test-path c:\windows\winsxs\pending.xml) -AND ([bool](get-content c:\windows\winsxs\pending.xml | Select-String 'postAction="reboot"'))) -OR 
  #Computer Rename pending
  ((get-itemproperty 'HKLM:SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\' | Select -Expand 'ComputerName') -ine (get-itemproperty 'HKLM:SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\' | Select -Expand 'ComputerName')) -OR 
  #Domain Join Pending
  ((Test-Path "HKLM:SYSTEM\CurrentControlSet\Services\Netlogon\JoinDomain") -OR (Test-Path "HKLM:SYSTEM\CurrentControlSet\Services\Netlogon\AvoidSpnSet")))
}
If (Test-PendingReboot)
{
  Write-Host "Shutting down in 10 seconds (giving time for orchestrating automation to close out)..."
  shutdown.exe /r /t 10
}
Else {Write-Host "A reboot is not pending, no action taken"}