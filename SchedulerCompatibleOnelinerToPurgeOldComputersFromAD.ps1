
#See this post for full details on why this code is helpful: PLACE URL

# This can be scheduled as SYSTEM on a domain controller - creates a CSV of whatever was removed
# AFTER RUNNING A TEST REPORT SCHEDULED UNDER SYSTEM ACCOUNT, Change $PurgeThreshold to less than 10 years and set $ReallyDelete $True
$ReallyDelete = $False ; $PurgeThreshold = -3650 ; $removelist = @(search-adaccount -accountinactive -datetime (get-date).adddays($PurgeThreshold) -computersonly) ; If ($removelist.count -lt 1) {Exit 0} ; $removelist | sort-object LastLogonDate | select-object Name, LastLogonDate, DistinguishedName, SID, ObjectGUID | export-csv -notypeinformation -path "$env:public\AD-ComputerCleanUp-At-$(Get-date -format 'yyyyMMddHHmm').csv" ; If ($ReallyDelete) {$removelist | Remove-ADComputer -confirm:$false }