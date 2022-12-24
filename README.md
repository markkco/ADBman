# ADBman - Android debug bridge (adb) CLI dialog script
## *WARNING!*
**Using Android debug bridge can render your android device useless! Be sure you know what you are doing. I am not responsible for any damage to your device you make by using this script!**

## ABOUT
The purpose of this script is a convenience when working with adb.
Requires `bash` and (GNU)`sed`.
Can be used with no root. 
Created in termux self-debug environment.

## FEATURES
* App list with filtering options
* Manage single app (enable/disable/suspend/hide[root]/permissions/clear-data/)
* History log
* Script config in ~/.adbman
* Currently works only for user 0

## TODO
* Finish app backup
* Add per user app management
* Add adb log view
* Add Settings 
* Add Tasks

## Known issues
* `adb shell dumpsys diskstats` does not show recent package storage change


