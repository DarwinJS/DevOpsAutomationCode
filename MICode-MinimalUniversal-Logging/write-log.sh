
# Why and How Blog Post: 
# Windows and Linux Versions: https://github.com/DarwinJS/DevOpsAutomationCode/tree/master/TCPConnectPreflightCheck

#Design Heuristic
# this is the simpliest, most broadly compatible bash log function I could devise.
# It is provided because shell scripts are frequently buried at the bottom of a complex stack and getting diagnostic data out can be challenging.
# It also prevents you from being dependent on your tooling users for proper logging implementation by making it a self-contained concern.
# It ensures a date string and that your logging goes to a system location that is subject to log collection
# To implement, update "echo" statements to "write-log"
# If you already have logging handled, then the below may unnecessary.

function write-log() {
  LOGSTRING="$(date +"%_b %e %H:%M:%S") $(hostname) USERDATA_SCRIPT: $1"
  echo "$LOGSTRING"
  echo "$LOGSTRING" >> /var/log/messages
}
