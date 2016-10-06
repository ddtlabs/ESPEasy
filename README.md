# ESPEasy
### FHEM Module To Control ESPEasy

Required: ESPEasy R128+

To bind this module into FHEM update service use the FHEM following commands:
* `update add https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`
* `update` 

To remove this module from FHEM update service use the FHEM following command:
* `update delete https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`

To install only once (no automatic updates via FHEM update command):
* `update all https://raw.githubusercontent.com/ddtlabs/ESPEasy/master/controls_ESPEasy.txt`

Or just download the module and copy it to your FHEM-Modul folder.

More information about FHEM update can be found here: 
[FHEM command reference](http://fhem.de/commandref.html#update) and [FHEMWIKI](http://www.fhemwiki.de/wiki/Update)

Release notes: [ReleaseNotes.md](ReleaseNotes.md)


#Command Reference#

<a name="ESPEasy"></a>
<h3>ESPEasy</h3>

<ul>
  <p>Provides control to ESP8266/ESPEasy</p>

  Notes:
  <ul>
    <li>You have to define a bridge device before any logical device can be
      defined.
    </li>
    <li>You have to configure your ESP to use "FHEM HTTP" controller protocol.
      Furthermore the ESP controller port and the
      FHEM ESPEasy bridge port must be the same, of cause.
    </li>
    <br>
  </ul>

  Requirements:
  <ul>
    <li>ESPEasy build &gt;= R128<br>
    </li>
    <li>perl module JSON<br>
      Use "cpan install JSON" or operating system's package manager to install
      Perl JSON Modul. Depending on your os the required package is named: 
      libjson-perl or perl-JSON.
    </li>
  </ul>

  <h3>ESPEasy Bridge</h3>

  <a name="ESPEasydefine"></a>
  <b>Define </b>(bridge)<br><br>
  
  <ul>
    <code>define &lt;name&gt; ESPEasy bridge &lt;port&gt;</code><br><br>

    <li>
      <code>&lt;name&gt;</code><br>
      Specifies a device name of your choise.<br>
      eg. <code>ESPBridge</code></li><br>

    <li>
      <code>&lt;port&gt;</code><br>
      Specifies tcp port for incoming http requests. This port must <u>not</u>
      be used by any other application or daemon on your system and must be in
      the range 1025..65535<br>
      eg. <code>8383</code> (ESPEasy FHEM HTTP plugin default)</li><br>

    <li>
      Example:<br>
      <code>define ESPBridge ESPEasy bridge 8383</code></li><br>
  </ul>

  <br><a name="ESPEasyget"></a>
  <b>Get </b>(bridge)<br><br>
  
  <ul>
    <li>&lt;reading&gt;<br>
      returns the value of the specified reading</li>
      <br>
      
    <li>user<br>
      returns username used by basic authentication for incoming requests.
      </li><br>

    <li>pass<br>
      returns password used by basic authentication for incoming requests.
      </li><br>
  </ul>

  <br><a name="ESPEasyset"></a>
  <b>Set </b>(bridge)<br><br>
  
  <ul>
    <li>help<br>
      Shows set command usage<br>
      required values: <code>help|pass|user</code></li><br>
      
    <li>pass<br>
      Specifies password used by basic authentication for incoming requests.<br>
      required value: <code>&lt;password&gt;</code><br>
      eg. : <code>set ESPBridge pass secretpass</code></li><br>
      
    <li>user<br>
      Specifies username used by basic authentication for incoming requests.<br>
      required value: <code>&lt;username&gt;</code><br>
      eg. : <code>set ESPBridge user itsme</code></li><br>
  </ul>

  <br><a name="ESPEasyattr"></a>
  <b>Attributes </b>(bridge)<br><br>
  
  <ul>
    <li>authentication<br>
      Used to enable basic authentication for incoming requests<br>
      Note that user, pass and authentication attribute must be set to activate
      basic authentication<br>
      Possible values: 0,1</li><br>

    <li>autocreate<br>
      Used to overwrite global autocreate setting<br>
      Possible values: 0,1<br>
      Default: 1</li><br>
      
    <li>autosave<br>
      Used to overwrite global autosave setting<br>
      Possible values: 0,1<br>
      Default: 1</li><br>
      
    <li>disable<br>
      Used to disable device<br>
      Possible values: 0,1</li><br>
      
    <li>httpReqTimeout<br>
      Specifies seconds to wait for a http answer from ESP8266 device<br>
      Possible values: 4..60<br>
      Default: 10 seconds</li><br>
      
    <a name="ESPEasyuniqIDs"></a>
    <li>uniqIDs<br>
      Used to generate unique identifiers (ESPName + DeviceName)<br>
      If you disable this attribut (set to 0) then your logical devices will be
      identified (and created) by the device name, only. Can be used to collect
      values from multiple ESP devices to a single FHEM device. Pay attention
      that value names must be unique in this case.<br>
      Possible values: 0,1<br>
      Default: 1 (enabled)</li><br>
  </ul>

  <h3>ESPEasy Device</h3>

  <a name="ESPEasydefineLogical"></a>
  <b>Define </b>(logical device)<br><br>
  
  <ul>
    Notes: Logical devices will be created automatically if any values are
    received by the bridge device and autocreate is not disabled. If you
    configured your ESP in a way that no data is send independently then you
    have to define logical devices. At least wifi rssi value could be defined
    to use autocreate.<br><br>
    
    <code>define &lt;name&gt; ESPEasy &lt;ip|fqdn&gt; &lt;port&gt;
    &lt;IODev&gt; &lt;identifier&gt;</code><br><br>

    <li>
      <code>&lt;name&gt;</code><br>
      Specifies a device name of your choise.<br>
      eg. <code>ESPxx</code></li><br>
      
    <li>
      <code>&lt;ip|fqdn&gt;</code><br>
      Specifies ESP IP address or hostname.<br>
      eg. <code>172.16.4.100</code><br>
      eg. <code>espxx.your.domain.net</code></li><br>
      
    <li>
      <code>&lt;port&gt;</code><br>
      Specifies http port to be used for outgoing request to your ESP. Should
      be: 80<br>
      eg. <code>80</code></li><br>
      
    <li>
      <code>&lt;IODev&gt;</code><br>
      Specifies your ESP bridge device. See above.<br>
      eg. <code>ESPBridge</code></li><br>
      
    <li>
      <code>&lt;identifier&gt;</code><br>
      Specifies an identifier that will bind your ESP to this device.
      Depending on attribut uniqIDs this must be &lt;esp name&gt; or 
      &lt;esp name&gt;_&lt;device name&gt;.<br>
      ESP name and device name can be found here:<br>
      &lt;esp name&gt;: =&gt; ESP GUI =&gt; Config =&gt; Main Settings =&gt;
      Name<br>
      &lt;device name&gt;: =&gt; ESP GUI =&gt; Devices =&gt; Edit =&gt;
      Task Settings =&gt; Name<br>
      eg. <code>ESPxx_DHT22</code><br>
      eg. <code>ESPxx</code></li><br>
      
    <li>  Example:<br>
      <code>define ESPxx ESPEasy 172.16.4.100 80 ESPBridge EspXX_SensorXX</code>
      </li><br>
  </ul>

  <br><a name="ESPEasyget"></a>
  <b>Get </b>(logical device)<br><br>
  
  <ul>
    <li>&lt;reading&gt;<br>
      returns the value of the specified reading</li><br>
      
    <li>pinMap<br>
      returns possible alternative pin names that can be used in commands</li>
      <br>
  </ul>

  <br><a name="ESPEasyset"></a>
  <b>Set </b>(logical device)<br><br>
  
  <ul>
    Notes:<br>
    - Commands are case insensitive.<br>
    - Users of Wemos D1 mini or NodeMCU can use Arduino pin names instead of
    GPIO numbers:<br>
    &nbsp;&nbsp;D1 =&gt; GPIO5, D2 =&gt; GPIO4, ...,TX =&gt; GPIO1 (see: get
    pinMap)<br>
    - low/high state can be written as 0/1 or on/off
    <br><br>

    <li>clearReadings<br>
      Delete all readings that are auto created by received sensor values<br>
      required values: <code>&lt;none&gt;</code></li><br>
      
    <li>help<br>
      Shows set command usage<br>
      required values: <code>a valid set command</code></li><br>
      
    <li>statusRequest<br>
      Trigger a statusRequest for configured GPIOs (see attribut pollGPIOs)
      and do a presence check<br>
      required values: <code>&lt;none&gt;</code></li><br>
      
    <li>Event<br>
      Create an event<br>
      required value: <code>&lt;string&gt;</code></li><br>
      
    <li>GPIO<br>
      Direct control of output pins (on/off)<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt;</code><br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li>PWM<br>
      Direct PWM control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a>
      for details</li><br>
      
    <li>PWMFADE<br>
      PWMFADE control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;target&gt; &lt;duration&gt;
      </code><br>
      pin: 0-3 (0=r,1=g,2=b,3=w), target: 0-1023, duration: 1-30 seconds.
      </li><br>

    <li>Pulse<br>
      Direct pulse control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt; &lt;duration&gt;</code>
      <br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li>LongPulse<br>
      Direct pulse control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt; &lt;duration&gt;</code>
      <br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>

    <li>Servo<br>
      Direct control of servo motors<br>
      required arguments: <code>&lt;servoNo&gt; &lt;pin&gt; &lt;position&gt;
      </code><br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li>lcd<br>
      Write text messages to LCD screen<br>
      required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
      see 
      <a target="_new" href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay
      </a> for details</li><br>
      
    <li>lcdcmd<br>
      Control LCD screen<br>
      required arguments: <code>&lt;on|off|clear&gt;</code><br>
      see 
      <a target="_new" href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay
      </a> for details</li><br>
      
    <li>mcpgpio<br>
      Control MCP23017 output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt;</code><br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/MCP23017">ESPEasy:MCP23017
      </a>for details</li><br>
      
    <li>oled<br>
      Write text messages to OLED screen<br>
      required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
      see
      <a target="_new" href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay
      </a> for details.</li><br>
      
    <li>oledcmd<br>
      Control OLED screen<br>
      required arguments: <code>&lt;on|off|clear&gt;</code><br>
      see 
      <a target="_new" href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay
      </a> for details.</li><br>
      
    <li>pcapwm<br>
      Control PCA9685 pwm pins<br>
      required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/PCA9685">ESPEasy:PCA9685</a>
      for details</li><br>
      
    <li>PCFLongPulse<br>
      Long pulse control on PCF8574 output pins<br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      for details</li><br>

    <li>PCFPulse<br>
      Pulse control on PCF8574 output pins<br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      for details</li><br>
      
    <li>pcfgpio<br>
      Control PCF8574 output pins<br>
      see <a target="_new" href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      </li><br>
      
    <li>raw<br>
      Can be used for own ESP plugins that are not considered at the moment.<br>
      Usage: raw &lt;cmd&gt; &lt;param1&gt; &lt;param2&gt; &lt;...&gt;<br>
      eg: raw myCommand 3 1 2</li><br>
      
    <li>status<br>
      Request esp device status (eg. gpio)<br>
      required values: <code>&lt;device&gt; &lt;pin&gt;</code><br>
      eg: <code>gpio 13</code></li><br>
  </ul>

  <br><a name="ESPEasyattr"></a>
  <b>Attributes</b> (logical device)<br><br>

  <ul>
    <li>adjustValue<br>
      Used to adjust sensor values<br>
      Must be a space separated list of &lt;reading&gt;:&lt;formula&gt;. 
      Reading can be a regexp. Formula can be an arithmetic expression like 
      'round(($VALUE-32)*5/9,2)'.
      If $VALUE is omitted in formula then it will be added to the beginning of
      the formula. So you can simple write 'temp:+20' or '.*:*4'<br>
      The following variables can be used if necessary: 
      <ul>
        <li>$VALUE contains the original value</li>
        <li>$READING contains the reading name</li>
        <li>$NAME contains the device name</li>
      </ul>
      Default: none<br>
      Eg. <code>attr ESPxx adjustValue humidity:+0.1 
      temperature+*:($VALUE-32)*5/9</code><br>
      Eg. <code>attr ESPxx adjustValue 
      .*:my_OwnFunction($NAME,$READING,$VALUE)</code></li><br>
      
    <li>disable<br>
      Used to disable device<br>
      Possible values: 0,1<br>
      Default: 0</li><br>

    <a name="ESPEasyInterval"></a>
    <li>Interval<br>
      Used to set polling interval for presence check and GPIOs in seconds<br>
      Possible values: secs &gt; 10. 0 will disable this feature.<br>
      Default: 300</li><br>
      
    <a name="ESPEasypollGPIOs"></a>
    <li>pollGPIOs<br>
      Used to enable polling for GPIOs status<br>
      Possible values: comma separated GPIO number list<br>
      Eg. <code>attr ESPxx pollGPIOs 13,D7,D2</code></li><br>
      
    <li>presenceCheck<br>
      Used to enable/disable presence check for ESPs<br>
      Presence check determines the presence of a device by readings age. If any
      reading of a device is newer than <a target="_blank" href="/fhem/docs/commandref.html#ESPEasyInterval">interval</a>
      seconds than it is marked as being present. This kind of check works for
      ESP devices in deep sleep too but require at least 1 reading that is
      updated regularly.<br>
      If the FHEM device contains values from more than 1 ESP (see Attribute
      <a target="_blank" href="/fhem/docs/commandref.html#ESPEasyuniqIDs">uniqIDs</a>) than there is an additional
      presence state: "partial absent (ip)" besides present and absent.<br>
      Possible values: 0,1<br>
      Default: 1 (enabled)</li><br>
      
    <li>readingPrefixGPIO<br>
      Specifies a prefix for readings based on GPIO numbers. For example:
      "set ESPxx gpio 15 on" will switch GPIO15 on. Additionally, there is an
      ESP devices (type switch input) that reports the same GPIO but with a
      name instead of GPIO number. To get the reading names synchron you can
      use this attribute. Helpful if you use pulse or longpuls command.<br>
      Default: GPIO</li><br>
      
    <li>readingSuffixGPIOState<br>
      Specifies a suffix for the state-reading of GPIOs (see Attribute
      <a target="_blank" href="/fhem/docs/commandref.html#ESPEasypollGPIOs">pollGPIOs</a>)<br>
      Default: no suffix
    </li><br>
    
    <li>readingSwitchText<br>
      Use on,off instead of 1,0 for readings if ESP device is a switch.<br>
      Possible values: 0,1<br>
      Default: 1 (enabled)</li><br>
      
    <li>setState<br>
      Summarize received values in state reading.<br>
      Set to 0 to disable this feature. A positive number determines the number
      of characters used for reading names. Only readings with an age less than
      <a target="_blank" href="/fhem/docs/commandref.html#ESPEasyInterval">interval</a> will be considered.<br>
      Reading state will be updated only if a value has been changed to reduce<br>
      events.
      Possible values: integer &gt;=0<br>
      Default: 3 (enabled with 3 characters abbreviation)</li><br>
  </ul>
</ul>
