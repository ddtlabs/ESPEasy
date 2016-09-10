### Release Notes:
```
0.1   - public release
0.1.1 - added internal timer to poll GPIO status
      - added attribut interval
      - added attribut pollGPIOs
      - improved logging
      - added esp command "status"
      - added statusRequest
      - commands are case insensitive, now
      - updated command reference
      - delete unknown readings
0.1.2 - renamed attribut interval to Interval
      - presence check
      - added statusRequest cmd
      - added forgotten longpulse command
0.1.3 - added internal VERSION
      - moved internal URLCMD to $hash->{helper}
      - added pin mapping for Wemos D1 mini, NodeMCU, ... 
      - within set commands
      - added state mapping (on->1 off->0) within all set commands
      - added set command "clearReadings" (GPIO readings will be wiped out)
      - added get command "pinMap" (displays pin mapping)
      - show usage if there are too few arguments
      - command reference adopted
0.2.0 - chanched module design to bridge/device version
0.2.1 - own tcp port (default 8383) for communication from esp to fhem
      - added basic authentication for incoming requests
      - added attribut readingPrefixGPIO
      - added attribut readingSuffixGPIOState
0.2.2 - fixed statusRequest/presentCheck
      - minor fixes: copy/paste errors...
      - approved logging to better fit dev guide lines
      - handle renaming of devices
      - commands are case sensitive again, sorry :(
0.2.3 - added pwmfade command #https://forum.fhem.de/index.php/topic,55728.msg480966.html#msg480966
      - added raw command to send own commands to esp. 
        usage: 'raw <newCommand> <param1> <param2> <...>'
0.2.4  - code cleanup
       - fixed "use TcpServerUtils"
       - removed controls_ESPEasy.txt from dev version
0.2.5  - fixed: keys on reference is experimental for perl versions >= 5.20?
0.3.0  - process json data if available (ESPEasy Version R126 required)
0.3.1  - added uniqIDs attribut
       - added get user/pass commands
0.3.2  - fixed auth bug
0.3.3  - state will contain readingvals
       - default room for bridge is ESPEasy, too.
       - Log outdated ESPEasy (without json) once.
       - JSON decoding error handling
0.3.4  - code cleanup
0.3.5  - dispatch ESP paramater to device internals if changed
       - added attribute setState (disable value mapping to state)
0.4.0  - command reference updated
0.4 RC1 - code cleanup
0.4.1  - improved removing of illegal chars in device + reading names
       - removed uniqID helper from bridge if undef device (IOwrite)
       - use peer IP instead of configured IP (could be modified by NAT/PAT)
       - added http response: 400 Bad Request
       - added http response: 401 Unauthorized
       - fixed oledcmd cmd usage string
       - improved presence detection (incoming requests)
0.4.2  - more unique dispatch separator
       - moved on|off translation for device type "SWITCH" from ESPEasy Software to this module.
       - new attribute readingSwitchText
0.4.3  - bug fix: Use of uninitialized value $ident:: in concatenation (.) or string at 34_ESPEasy.pm line 867. Forum: topic,55728.msg488459.html
0.4.4  - modified behavior of attribute setState (# of characters in state, 0 = disabled)
       - fixed: Use of uninitialized value in string ne at ./FHEM/34_ESPEasy.pm line 9xx.
       - code and command reference cleanup
       - misc logging modifications

```
