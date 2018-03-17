
#See this post for full details on why this code is helpful: https://cloudywindows.io/post/culling-dead-computer-records-from-ad-with-a-scheduled-powershell-oneliner/

# This can be scheduled as SYSTEM on a domain controller - creates a CSV of whatever was removed
# AFTER RUNNING A TEST REPORT SCHEDULED UNDER SYSTEM ACCOUNT, Change $PurgeThreshold to less than 10 years and set $ReallyDelete $True
$ReallyDelete = $False ; $PurgeThreshold = -3650 ; $RemoveList = @(Search-ADAccount -AccountInactive -DateTime (get-date).AddDays($PurgeThreshold) -ComputersOnly) ; If ($RemoveList.count -lt 1) {Exit 0} ; $RemoveList | Sort-Object LastLogonDate | Select-Object Name, LastLogonDate, DistinguishedName, SID, ObjectGUID | Export-Csv -NoTypeInformation -Path "$env:public\AD-ComputerCleanUp-At-$(Get-date -format 'yyyyMMddHHmm').csv" ; If ($ReallyDelete) {$RemoveList | Remove-ADComputer -Confirm:$False}