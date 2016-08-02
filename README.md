# ESPEasy
### FHEM Module To Control ESPEasy

To bind this module into FHEM update service use the FHEM following commands:
* `update add https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`
* `update` 

To remove this module from FHEM update service use the FHEM following command:
* `update delete https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`

To install only once (no automatic updates via FHEM update command):
* `update https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`

Or just download the module and copy it to your FHEM-Modul folder.

More information about FHEM update can be found here:

[FHEMWIKI](http://www.fhemwiki.de/wiki/Update)

[FHEM command reference](http://fhem.de/commandref.html#update)


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
```
