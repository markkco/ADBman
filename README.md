# ADBman - Android debug bridge (adb) CLI dialog script
## *WARNING!*
**Using Android debug bridge can render your android device useless! Be sure you know what you are doing. I am not responsible for any damage to your device you make by using this script!**

## ABOUT
The purpose of this script is a convenience when working with android debug bridge.
Requires:
* `adb` with connected device,
* `bash`,
* `dialog`,
* (GNU)`sed`.
Can be used with no root. 
Created in `termux` self-debug environment.

## FEATURES
* App list with filtering options
* Manage single app:
    * install-existing/uninstall
    * enable/disable
    * suspend/unsuspend
    * hide/unhide [root]
    * manage runtime permissions
    * clear data
    * backup/restore
    * view dump
* History log
* Script config in ~/.adbman

## TODO
* Finish app backup
* Add per user app management
* Add adb log view
* Add Settings 

## Known issues
* `adb shell dumpsys diskstats` does not show recent package storage change


