
# Why and How Blog Post: https://cloudywindows.io/post/mission-impossible-code-part-2-extreme-multilingual-iac-via-standard-code-for-preflight-tcp-connect-testing-a-list-of-endpoints-in-both-bash-and-powershell/
# Windows and Linux Versions: https://github.com/DarwinJS/DevOpsAutomationCode/tree/master/MICode-MinimalUniversal-TCPConnectPreflightCheck

#Design Heuristic
# 1. This approach does not require the nc command which might not be on some minimalized hosts like containers
# 2. Receives a single, formatted string (rather than an array or hash or other data type) to:
#  * make it easy to pass a list from any orchestration system regardless of data types it supports
#  * make it easy to pass through as many layers of enclosing automation as necessary without having 
#      to escape or translate sophisticated data types
#  * enables the arguments for the Windows and Linux version to 
#      be exactly the same - in case you are passing into something that accomodates both platforms

# Consider implementing the Minimal, Universal Logging code with the below: https://github.com/DarwinJS/DevOpsAutomationCode/tree/master/MICode-MinimalUniversal-Logging

urlportpairlist="outlook.com=80 google.com=80 test.com=442"
failurecount=0
for urlportpair in $urlportpairlist; do
  set -- $(echo $urlportpair | tr '=' ' ') ; url=$1 ; port=$2
  echo "TCP Test of $url on $port"
  timeout 3 bash -c "cat < /dev/null > /dev/tcp/$url/$port"
  if [ "$?" -ne 0 ]; then
    echo "  Connection to $url on port $port failed"
    ((failurecount++))
  else
    echo "  Connection to $url on port $port succeeded"
  fi
done

if [ $failurecount -gt 0 ]; then
 echo "$failurecount tcp connect tests failed."
 exit $failurecount
fi