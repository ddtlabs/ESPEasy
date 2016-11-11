# $Id: 34_ESPEasy.pm 66 2016-10-02 08:30:00Z dev0 $
################################################################################
#
#  34_ESPEasy.pm is a FHEM Perl module to control ESP8266 / ESPEasy
#
#  Copyright 2016 by dev0 (http://forum.fhem.de/index.php?action=profile;u=7465)
#
#  This file is part of FHEM.
#
#  Fhem is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  Fhem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with fhem.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
#
# ESPEasy change log:
#
# 2016-07-20  0.1    - public release
# 2016-07-29  0.1.1  - added internal timer to poll gpios
#                    - added attr Interval
#                    - added attr pollGPIOs
#                    - improved logging
#                    - added esp command status
#                    - added statusRequest
#                    - call commands are case insensitive, now
#                    - updated command reference
#                    - delete unknown readings
# 2016-07-31  0.1.2  - renamed attribut interval to Interval
#                    - presence check
#                    - added statusRequest cmd
#                    - added forgotten longpulse command
# 2016-08-03  0.1.3  - added internal VERSION
#                    - moved internal URLCMD to $hash->{helper}
#                    - added pin mapping for Wemos D1 mini, NodeMCU, ... 
#                      within set commands
#                    - added state mapping (on->1 off->0) within all set commands
#                    - added set command "clearReadings" (GPIO readings will be wiped out)
#                    - added get command "pinMap" (displays pin mapping)
#                    - show usage if there are too few arguments
#                    - command reference adopted
# 2016-08-09  0.2.0  - chanched module design to bridge/device version
# 2016-08-10  0.2.1  - own tcp port (default 8383) for communication from esp to fhem
#                    - added basic authentication for incoming requests
#                    - added attribut readingPrefixGPIO
#                    - added attribut readingSuffixGPIOState
# 2016-08-11  0.2.2  - fixed statusRequest/presentCheck
#                    - minor fixes: copy/paste errors...
#                    - approved logging to better fit dev guide lines
#                    - handle renaming of devices
#                    - commands are case sensitive again, sorry :(
# 2016-08-11  0.2.3  - added pwmfade command: Forum topic,55728.msg480966.html
#                    - added raw command to send own commands to esp. 
#                      usage: 'raw <newCommand> <param1> <param2> <...>'
# 2016-08-12  0.2.4  - code cleanup
#                    - fixed "use TcpServerUtils"
#                    - removed controls_ESPEasy.txt from dev version
# 2016-08-13  0.2.5  - fixed PERL WARNING: keys on reference is experimental
#                      for perl versions >= 5.20?
# 2016-08-20  0.3.0  - process json data only (ESPEasy Version Rxxx required)
#             0.3.1  - added uniqIDs attribut
#                    - added get user/pass
# 2016-08-22  0.3.2  - fixed auth bug
# 2016-08-24  0.3.3  - state will contain readingvals
#                    - default room for bridge is ESPEasy, too.
#                    - Log outdated ESPEasy (without json) once.
#                    - eval JSON decoding
# 2016-08-26  0.3.4  - ESP parameter -> Internals
# 2016-08-27  0.3.5  - dispatch ESP paramater to device internals if changed
#                    - added attribute setState (disable value mapping to state)
# 2016-08-27  0.4 RC1  - code cleanup
# 2016-08-29  0.4.1  - improved removing of illegal chars in device + reading names
#                    - removed uniqID helper from bridge if undef device (IOwrite)
#                    - use peer IP instead of configured IP (could be modified by NAT/PAT)
#                    - added http response: 400 Bad Request
#                    - added http response: 401 Unauthorized
#                    - fixed oledcmd cmd usage string
#                    - improved presence detection (incoming requests)
# 2016-09-05  0.4.2  - more unique dispatch separator
#                    - moved on|off translation for device type "SWITCH" from
#                      ESPEasy Software to this module.
#                    - new attribute readingSwitchText
# 2016-09-06  0.4.3  - bug fix: Use of uninitialized value $ident:: in 
#                      concatenation (.) or string at 34_ESPEasy.pm line 867.
#                      Forum: topic,55728.msg488459.html
# 2016-09-10  0.4.4  - modified behavior of attribute setState (# of characters in state, 0 = disabled)
#                    - fixed: PERL WARNING: Use of uninitialized value in string ne at ./FHEM/34_ESPEasy.pm line 9xx.
#                    - code and command reference cleanup
#                    - misc logging modifications
# 2016-09-12  0.4.5  - timestamp of reading state will not be changed if state == opened,present or absent
#                    - added internal INTERVAL
# 2016-09-17  0.4.6  - Attr Interval can be set 0 to disable presence check and polling
#                    - removed deprecated code for old ESPEasy Versions without json support
#                    - reworked dispatching values
#                    - reworked presence detection (no more polling, check readings age)
#                    - added attribut adjustValue (see command ref for details)
#                    - added internal ESP_CONFIG -> EspIP:version,sleep,unit
#                    - added internal UNIQIDS to devices
# 2016-09-29  0.4.7  - command reference updated
# 2016-09-30  0.4.8  - logging adopted
# 2016-10-01  0.4.9  - fixed check of empty device name, value name and value in received data
# 2016-10-02  0.5.0  - eval JSON decoding in http response
#                    - removed Authorization String from debug log
#                    - combined internals logging
#                    - check for temporary bridge device in deleteFn and do no IOWrite
#                      see: https://forum.fhem.de/index.php/topic,55728.msg497366.html#msg497366
#                    - added check that fhem.pl is new enough (11000/2016-03-05)
#                      see: https://forum.fhem.de/index.php/topic,55728.msg497094.html#msg497094
# 2016-10-03  0.5.1  - optimized logging
# 2016-10-03  0.5.2  - fixed: PERL WARNING: Use of uninitialized value in substitution (s///) at ./FHEM/34_ESPEasy.pm line 569.
# 2016-10-04  0.5.3  - adopted deletion of keys in hash->helper if a device will be deleted
#                    - fixed get <bridge> user/pass
#                    - code cleanup
#                    - fixed: PERL WARNING: Ambiguous use of -time resolved as -&time() at ./FHEM/34_ESPEasy.pm line 1283
# 2016-10-06  0.5.4  - improved closing tcp connects
# 2016-10-23  0.6.0  - increase verbose level for startup/shutdown log messages
#                    - moved attribute handling to NotifyFn
#                    - new attribute allowedIPs
#                    - new attribute parseCmdResponse
#                    - disabled parsing httpRequests by default, enable with attr parseCmdResponse
#                    - more relaxed checking of existenz of 'esp name' and 'device name'.
#                    - dispatch error msgs to device, show WARNING in internals
#                    - added default attributes
# 2016-10-23  0.6.1  - changed default behavior allowedIPs feature to 'allow'
# 2016-10-25  0.6.2  - added attribut deniedIPs
# 2016-10-26  0.6.3  - close open tcp session immediately if ESP is configured 
#                      to go to deep sleep (EPSEasy bug?)
# 2016-10-29  0.6.4  - fixed faulty presence detection after FHEM restart
# 2016-11-05  0.6.5  - added space between reading und value in state (Forum #55728.msg515626)
#                    - attribute uniqIDs is deprecated and will be removed soon
#                    - added function declarations (Forum #55728.msg511921)
#                    - new attribute combineDevices (Used to gather all ESP devices of a single ESP into 1 FHEM device even if different ESP devices names are used)
# 2016-11-10  0.6.6  - minor fixes
#
################################################################################


package main;

use strict;
use warnings;
use Data::Dumper;
use MIME::Base64;
use TcpServerUtils;
use HttpUtils;

# ------------------------------------------------------------------------------
# global and default values
# ------------------------------------------------------------------------------
my $ESPEasy_minESPEasyBuild = 128;     # informational
my $ESPEasy_minJsonVersion  = 1.02;    # checked in received data
my $ESPEasy_version         = 0.66;    # Version of this module
my $dInterval               = 300;     # default interval
my $dhttpReqTimeout         = 10;      # default timeout http req + selfdestroy

# ------------------------------------------------------------------------------
# "setCmds" => "min. number of parameters"
# ------------------------------------------------------------------------------
my %ESPEasy_setCmds = (
  "gpio"           => "2",
  "pwm"            => "2",
  "pwmfade"        => "3",
  "pulse"          => "3",
  "longpulse"      => "3",
  "servo"          => "3",
  "lcd"            => "3",
  "lcdcmd"         => "1",
  "mcpgpio"        => "2",
  "oled"           => "3",
  "oledcmd"        => "1",
  "pcapwm"         => "2",
  "pcfgpio"        => "2",
  "pcfpulse"       => "3",
  "pcflongpulse"   => "3",
  "status"         => "2",
  "raw"            => "1",
  "statusrequest"  => "0", 
  "clearreadings"  => "0",
  "help"           => "1"
);

# ------------------------------------------------------------------------------
# "setCmds" => "syntax", ESPEasy_paramPos() will parse for some <.*> positions
# ------------------------------------------------------------------------------
my %ESPEasy_setCmdsUsage = (
  "gpio"           => "gpio <pin> <0|1|off|on>",
  "pwm"            => "pwm <pin> <level>",
  "pulse"          => "pulse <pin> <0|1|off|on> <duration>",
  "longpulse"      => "longpulse <pin> <0|1|off|on> <duration>",
  "servo"          => "servo <servoNo> <pin> <position>",
  "lcd"            => "lcd <row> <col> <text>",
  "lcdcmd"         => "lcdcmd <on|off|clear>",
  "mcpgpio"        => "mcpgpio <pin> <0|1|off|on>",
  "oled"           => "oled <row> <col> <text>",
  "oledcmd"        => "oledcmd <on|off|clear>",
  "pcapwm"         => "pcapwm <pin> <Level>",
  "pcfgpio"        => "pcfgpio <pin> <0|1|off|on>",
  "pcfpulse"       => "pcfpulse <pin> <0|1|off|on> <duration>",    #missing docu
  "pcflongpulse"   => "pcflongPulse <pin> <0|1|off|on> <duration>",#missing docu
  "status"         => "status <device> <pin>",
  #https://forum.fhem.de/index.php/topic,55728.msg480966.html#msg480966
  "pwmfade"        => "pwmfade <pin> <target> <duration>",
  "raw"            => "raw <esp_comannd> <...>",

  "statusrequest"  => "statusRequest",
  "clearreadings"  => "clearReadings",
  "help"           => "help <".join("|", sort keys %ESPEasy_setCmds).">"
);

# ------------------------------------------------------------------------------
# Bridge "setCmds" => "min. number of parameters"
# ------------------------------------------------------------------------------
my %ESPEasy_setBridgeCmds = (
  "user"           => "0",
  "pass"           => "0",
  "help"           => "1"
);

# ------------------------------------------------------------------------------
# "setBridgeCmds" => "syntax", ESPEasy_paramPos() parse for some <.*> positions
# ------------------------------------------------------------------------------
my %ESPEasy_setBridgeCmdsUsage = (
  "user"           => "user <username>",
  "pass"           => "pass <password>",
  "help"           => "help <".join("|", sort keys %ESPEasy_setBridgeCmds).">"
);

# ------------------------------------------------------------------------------
# pin names can be used instead of gpio numbers.
# ------------------------------------------------------------------------------
my %ESPEasy_pinMap = (
  "D0"   => 16, 
  "D1"   => 5, 
  "D2"   => 4,
  "D3"   => 0,
  "D4"   => 2,
  "D5"   => 14,
  "D6"   => 12,
  "D7"   => 13,
  "D8"   => 15,
  "D9"   => 3,
  "D10"  => 1,

  "RX"   => 3,
  "TX"   => 1,
  "SD2"  => 9,
  "SD3"  => 10
);


# ------------------------------------------------------------------------------
#grep ^sub 34_ESPEasy.pm | awk '{print $1" "$2";"}'
sub ESPEasy_Initialize($);
sub ESPEasy_Define($$);
sub ESPEasy_Get($@);
sub ESPEasy_Set($$@);
sub ESPEasy_Read($);
sub ESPEasy_Write($$$$$@);
sub ESPEasy_Notify($$);
sub ESPEasy_Rename();
sub ESPEasy_Attr(@);
sub ESPEasy_Undef($$);
sub ESPEasy_Shutdown($);
sub ESPEasy_Delete($$);
sub ESPEasy_dispatch($$$@);
sub ESPEasy_dispatchParse($$$);
sub ESPEasy_autocreate($$$$);
sub ESPEasy_httpRequest($$$$$$@);
sub ESPEasy_httpRequestParse($$$);
sub ESPEasy_statusRequest($);
sub ESPEasy_pollGPIOs($);
sub ESPEasy_resetTimer($;$);
sub ESPEasy_intAt2helper($);
sub ESPEasy_tcpServerOpen($);
sub ESPEasy_header2Hash($);
sub ESPEasy_isAuthenticated($$);
sub ESPEasy_isParseCmd($$);
sub ESPEasy_sendHttpClose($$$);
sub ESPEasy_paramPos($$);
sub ESPEasy_paramCount($);
sub ESPEasy_clearReadings($);
sub ESPEasy_checkVersion($$$$);
sub ESPEasy_checkPresence($;$);
sub ESPEasy_setESPConfig($);
sub ESPEasy_setState($);
sub ESPEasy_adjustValue($$$);
sub ESPEasy_isPmInstalled($$);
sub ESPEasy_isAttrCombineDevices($);
sub ESPEasy_isCombineDevices($$$);
sub ESPEasy_isValidPeer($);
sub ESPEasy_isIPv64Range($);
sub ESPEasy_isPeerAllowed($$);
sub ESPEasy_ip2bin($);
sub ESPEasy_expandIPv6($);
sub ESPEasy_addrToCIDR($);
sub ESPEasy_dottedNmToCIDR($);
sub ESPEasy_isIPv4($);
sub ESPEasy_isIPv6($);
sub ESPEasy_isIPv64($);
sub ESPEasy_isNmDotted($);
sub ESPEasy_isNmCIDRv4($);
sub ESPEasy_isNmCIDRv6($);
sub ESPEasy_isFqdn($);
sub ESPEasy_isHostname($);
sub ESPEasy_whoami();


# ------------------------------------------------------------------------------
sub ESPEasy_Initialize($)
{
  my ($hash) = @_;

  #common
  $hash->{DefFn}      = "ESPEasy_Define";
  $hash->{GetFn}      = "ESPEasy_Get";
  $hash->{SetFn}      = "ESPEasy_Set";
  $hash->{AttrFn}     = "ESPEasy_Attr";
  $hash->{UndefFn}    = "ESPEasy_Undef";
  $hash->{ShutdownFn} = "ESPEasy_Shutdown";
  $hash->{DeleteFn}   = "ESPEasy_Delete";
  $hash->{RenameFn}   = "ESPEasy_Rename";
  $hash->{NotifyFn}   = "ESPEasy_Notify";

  #provider
  $hash->{ReadFn}     = "ESPEasy_Read"; #ESP http request will be parsed here
  $hash->{WriteFn}    = "ESPEasy_Write"; #called from logical module's IOWrite
  $hash->{Clients}    = ":ESPEasy:"; #used by dispatch,$hash->{TYPE} of receiver 
  my %matchList       = ( "1:ESPEasy" => ".*" );
  $hash->{MatchList}  = \%matchList;

  #consumer
  $hash->{ParseFn}    = "ESPEasy_dispatchParse";
  $hash->{Match}      = ".+";              

  $hash->{AttrList}   = "allowedIPs "
                       ."authentication:1,0 "
                       ."autocreate:1,0 "
                       ."autosave:1,0 "
                       ."deniedIPs "
                       ."disable:1,0 "
                       ."do_not_notify:0,1 "
                       ."httpReqTimeout "
                       ."IODev "
                       ."Interval "
                       ."adjustValue "
                       ."parseCmdResponse "
                       ."pollGPIOs "
                       ."presenceCheck:1,0 "
                       ."readingPrefixGPIO "
                       ."readingSuffixGPIOState "
                       ."readingSwitchText:1,0 "
                       ."setState:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100 "
                       ."combineDevices "
                       ."uniqIDs:1,0 "
                       .$readingFnAttributes;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Define($$)  # only called when defined, not on reload.
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  my $usg = "\nUse 'define <name> ESPEasy <bridge> <PORT>".
            "\nUse 'define <name> ESPEasy <ip|fqdn> <PORT> <IODev> <IDENT>";
  return "Wrong syntax: $usg" if(int(@a) < 3);

  my $name  = $a[0];
  my $type  = $a[1];
  my $host  = $a[2];
  my $port  = $a[3] if defined $a[3];
  my $iodev = $a[4] if defined $a[4];
  my $ident = $a[5] if defined $a[5];

  return "ERROR: only 1 ESPEasy bridge can be defined!"
    if($host eq "bridge" && $modules{ESPEasy}{defptr}{BRIDGE});
  return "ERROR: missing arguments for subtype device: $usg"
    if ($host ne "bridge" && !(defined $a[4]) && !(defined $a[5]));
  return "ERROR: too much arguments for a bridge: $usg"
    if ($host eq "bridge" && defined $a[4]);
  return "ERROR: perl module JSON is not installed"
    if (ESPEasy_isPmInstalled($hash,"JSON"));

  (ESPEasy_isIPv4($host) || ESPEasy_isFqdn($host) || $host eq "bridge")
    ? $hash->{HOST} = $host
    : return "ERROR: invalid IPv4 address, fqdn or keyword bridge: '$host'";

  # check fhem.pl version (internalTimer modifications are required)
  # https://forum.fhem.de/index.php/topic,55728.msg497094.html#msg497094
  AttrVal('global','version','') =~ m/^fhem.pl:(\d+)\/.*$/;
  return "ERROR: fhem.pl is too old to use $type module."
        ." Version 11000/2016-03-05 is required at least."
    if (not(defined $1) || $1 < 11000);
  
  $hash->{PORT}      = $port if defined $port;
  $hash->{IDENT}     = $ident if defined $ident;
  $hash->{VERSION}   = $ESPEasy_version;
  $hash->{NOTIFYDEV} = "global";
  
  #--- BRIDGE -------------------------------------------------
  if ($hash->{HOST} eq "bridge") {
    $hash->{SUBTYPE} = "bridge";
    $modules{ESPEasy}{defptr}{BRIDGE} = $hash;
    Log3 $hash->{NAME}, 2, "$type $name: Opening bridge on port tcp/$port (v$ESPEasy_version)";
    ESPEasy_tcpServerOpen($hash);
    if ($init_done && !defined( $hash->{OLDDEF})) {
    #if (not defined getKeyValue($type."_".$name."-firstrun")) {
      CommandAttr(undef,"$name room $type");
      CommandAttr(undef,"$name group $type Bridge");
      CommandAttr(undef,"$name authentication 0");
      CommandAttr(undef,"$name combineDevices 0");
      setKeyValue($type."_".$name."-firstrun","done");
    }
    # only informational 
    my $u = getKeyValue($type."_".$name."-user");
    $hash->{USER} = (defined $u) ? $u : "not defined yet !!!";
    my $p = getKeyValue($type."_".$name."-pass");
    $hash->{PASS} = (defined $p) ? "*" x length($p) : "not defined yet !!!";
  } 

  #--- DEVICE -------------------------------------------------
  else {
    $hash->{INTERVAL} = $dInterval;
    $hash->{SUBTYPE} = "device";
    AssignIoPort($hash,$iodev) if(not defined $hash->{IODev});
    InternalTimer(gettimeofday()+5+rand(5), "ESPEasy_statusRequest", $hash);
    readingsSingleUpdate($hash, 'state', 'opened',1);
    my $io = (defined($hash->{IODev}{NAME})) ? $hash->{IODev}{NAME} : "none";
    Log3 $hash->{NAME}, 4, "$type $name: Opened for $ident $host:$port using bridge $io";
  }

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Get($@)
{
  my ($hash, @a) = @_;
  return "argument is missing" if(int(@a) != 2);

  my $reading = $a[1];
  my $ret;
  if (lc $reading eq "pinmap") {
    $ret .= "\nName => GPIO\n";
    $ret .= "------------\n";
    foreach (sort keys %ESPEasy_pinMap) {
      $ret .= $_." " x (5-length $_ ) ."=> $ESPEasy_pinMap{$_}\n";
    }
    return $ret;

  } elsif (lc $reading =~ /(user|pass)/) {
    $ret .= "$reading:\n";
    $ret .= getKeyValue($hash->{TYPE}."_".$hash->{NAME}."-".$reading);
    return $ret;

  } elsif (exists($hash->{READINGS}{$reading})) {
    return defined($hash->{READINGS}{$reading})
      ? $hash->{READINGS}{$reading}{VAL}
      : "no such reading: $reading";

  } else {
    $ret = "unknown argument $reading, choose one of";
    foreach my $reading (sort keys %{$hash->{READINGS}}) {
      $ret .= " $reading:noArg";
  }
    
  return ($hash->{SUBTYPE} eq "bridge") 
    ? $ret . " user:noArgs pass:noArgs" 
    : $ret . " pinMap:noArg";
  }
}


# ------------------------------------------------------------------------------
sub ESPEasy_Set($$@)
{
  my ($hash, $name, $cmd, @params) = @_;
  my ($type,$self) = ($hash->{TYPE},ESPEasy_whoami());
  $cmd = lc($cmd) if $cmd;

  return if (IsDisabled $name);

  Log3 $name, 3, "$type $name: set $name $cmd ".join(" ",@params) 
    if $cmd !~  m/^(\?|user|pass)$/;

  # ----- BRDIGE ----------------------------------------------
  if ($hash->{SUBTYPE} eq "bridge") {

    # are there all required argumets?
    if($ESPEasy_setBridgeCmds{$cmd} 
    && scalar @params < $ESPEasy_setBridgeCmds{$cmd}) {
      Log3 $name, 2, "$type $name: Missing argument: 'set $name $cmd "
                     .join(" ",@params)."'";
      return "Missing argument: $cmd needs at least "
            ."$ESPEasy_setBridgeCmds{$cmd} parameter(s)\n"
            ."Usage: 'set $name $ESPEasy_setBridgeCmdsUsage{$cmd}'";
    }
  
    # handle unknown cmds
    if(!exists $ESPEasy_setBridgeCmds{$cmd}) {
      my @cList = sort keys %ESPEasy_setBridgeCmds;
      my $clist = join(" ", @cList);
      my $hlist = join(",", @cList);
      $clist =~ s/help/help:$hlist/; # add all cmds as params to help cmd
      return "Unknown argument $cmd, choose one of ". $clist;
    }

    if ($cmd eq "help") {
      my $usage = $ESPEasy_setBridgeCmdsUsage{$params[0]};
      $usage     =~ s/Note:/\nNote:/g;
      return "Usage: set $name $usage";
    }

    elsif ($cmd =~ /^user|pass$/ ) {
      setKeyValue($hash->{TYPE}."_".$hash->{NAME}."-".$cmd,$params[0]);
      # only informational 
      if (defined $params[0]) {
        $hash->{uc($cmd)} = ($cmd eq "user") ? $params[0] 
                                             : "*" x length($params[0]);
      } else {
        $hash->{uc($cmd)} = "not defined yet !!!";
      }
    }
  }

  # ----- DEVICE ----------------------------------------------
  else {

    # are there all required argumets?
    if($ESPEasy_setCmds{$cmd} && scalar @params < $ESPEasy_setCmds{$cmd}) {
      Log3 $name, 2, "$type $name: Missing argument: "
                    ."'set $name $cmd ".join(" ",@params)."'";
      return "Missing argument: $cmd needs at least $ESPEasy_setCmds{$cmd} ".
             "parameter(s)\n"."Usage: 'set $name $ESPEasy_setCmdsUsage{$cmd}'";
    }

    # handle unknown cmds
    if(!exists $ESPEasy_setCmds{$cmd}) {
      my @cList = sort keys %ESPEasy_setCmds;
      my $clist = join(" ", @cList);
      my $hlist = join(",", @cList);
      $clist =~ s/help/help:$hlist/; # add all cmds as params to help cmd
      return "Unknown argument $cmd, choose one of ". $clist;
    }

    # pin mapping (eg. D8 -> 15)
    my $pp = ESPEasy_paramPos($cmd,'<pin>');
    if ($pp && $params[$pp-1] =~ /^[a-zA-Z]/) {
      Log3 $name, 5, "$type $name: Pin mapping ". uc $params[$pp-1] .
                     " => $ESPEasy_pinMap{uc $params[$pp-1]}";
      $params[$pp-1] = $ESPEasy_pinMap{uc $params[$pp-1]};
    }

    # onOff mapping (on/off -> 1/0)
    $pp = ESPEasy_paramPos($cmd,'<0|1|off|on>');
    if ($pp && not($params[$pp-1] =~ /^0|1$/)) {
      my $state;
      if ($params[$pp-1] =~ /^off$/i) {
        $state = 0;
      }
      elsif ($params[$pp-1] =~ /^on$/i) {
        $state = 1;
      }
      else {
        Log3 $name, 2, "$type $name: $cmd ".join(" ",@params)." => unknown argument: '$params[$pp-1]'";
        return undef;      
      }
      Log3 $name, 5, "$type $name: onOff mapping ". $params[$pp-1]." => $state";
      $params[$pp-1] = $state;
    }



    if ($cmd eq "help") {
      my $usage = $ESPEasy_setCmdsUsage{$params[0]};
      $usage     =~ s/Note:/\nNote:/g;
      return "Usage: set $name $usage";
    }

    if ($cmd eq "statusrequest") {
      ESPEasy_statusRequest($hash);
      return undef;
    }

    if ($cmd eq "clearreadings") {
      ESPEasy_clearReadings($hash);
      return undef;
    }

    Log3 $name, 5, "$type $name: IOWrite(\$defs{$hash->{NAME}}, $hash->{HOST}, $hash->{PORT}, ".
                   "$hash->{IDENT}, $cmd, ".join(",",@params).")";

    Log3 $name, 2, "$type $name: Sending commands is not recommended while uniqIDs mode is disabled."
      if (defined $hash->{UNIQIDS} && $hash->{UNIQIDS} == 0 && scalar keys %{$hash->{helper}{internals}} > 1);

    Log3 $name, 2, "$type $name: Device seems to be in sleep mode, sending command nevertheless."
      if (defined $hash->{helper}{internals}{$hash->{HOST}}{SLEEP}
      && $hash->{helper}{internals}{$hash->{HOST}}{SLEEP} ne "0");

    my $parseCmd = ESPEasy_isParseCmd($hash,$cmd);
    IOWrite($hash, $hash->{HOST}, $hash->{PORT}, $hash->{IDENT}, $parseCmd, $cmd, @params);

  } # DEVICE

return undef
}

# ------------------------------------------------------------------------------
sub ESPEasy_Read($) {

  my ($hash) = @_;                             #hash of temporary child instance
  my $name   = $hash->{NAME};
  my $bhash  = $modules{ESPEasy}{defptr}{BRIDGE};     #hash of original instance
  my $bname  = $bhash->{NAME};
  my $btype  = $bhash->{TYPE};
  $Data::Dumper::Indent = 0;
  $Data::Dumper::Terse  = 1;

  # Accept and create a child
  if( $hash->{SERVERSOCKET} ) {
    my $aRet = TcpServer_Accept($hash,"ESPEasy");
    return;
  }

  # use received IP instead of configured one (NAT/PAT could have modified)
  my $peer = $hash->{PEER}; 

  # Read 1024 byte of data
  my $buf;
  my $ret = sysread($hash->{CD}, $buf, 1024);

  # If there is an error in connection return
  if( !defined($ret ) || $ret <= 0 ) {
    CommandDelete( undef, $hash->{NAME} );
    return;
  }

  $bhash->{SESSIONS} = scalar devspec2array("TYPE=$btype:FILTER=TEMPORARY=1")-1;

  # Check attr disabled
  return if (IsDisabled $bname);

  # Check allowed IPs
  if ( !( ESPEasy_isPeerAllowed($peer,AttrVal($bname,"allowedIPs",1)) &&
         !ESPEasy_isPeerAllowed($peer,AttrVal($bname,"deniedIPs",0)) ) ) {
    Log3 $bname, 2, "$btype $name: Peer address rejected";
    return;
  }
  Log3 $bname, 4, "$btype $name: Peer address accepted";
  
  my @data = split( '\R\R', $buf );
  my $header = ESPEasy_header2Hash($data[0]);
  
  # mask password in authorization header with ****
  my $logHeader = { %$header };
  $logHeader->{Authorization} =~ s/Basic\s.*\s/Basic ***** / if defined $logHeader->{Authorization};
  # Dump logHeader
  Log3 $bname, 5, "$btype $name: Received header: ".Dumper($logHeader) if defined $logHeader;
  # Dump content
  Log3 $bname, 5, "$btype $name: Received content: $data[1]" if defined $data[1];

  # Check content length if defined
  if (defined $header->{'Content-Length'} 
  && $header->{'Content-Length'} != length($data[1])) {
    Log3 $bname, 2, "$btype $name: Invalid content length ".
                    "($header->{'Content-Length'} != ".length($data[1]).")";
    Log3 $bname, 2, "$btype $name: Received content: $data[1]"
      if defined $data[1];
    ESPEasy_sendHttpClose($hash,"400 Bad Request","");
    return;
  }

  # check authorization
  if (!defined ESPEasy_isAuthenticated($hash,$header->{Authorization})) {
    ESPEasy_sendHttpClose($hash,"401 Unauthorized","");
    return;
  }

  # No error occurred, send http respose OK to ESP
  ESPEasy_sendHttpClose($hash,"200 OK",""); #if !grep(/"sleep":1/, $data[1]);

  # JSON received...
  my $json;
  if (defined $data[1] && $data[1] =~ m/"module":"ESPEasy"/) {

    # remove illegal chars but keep JSON relevant chars.
    $data[1] =~ s/[^A-Za-z\d_\.\-\/\{}:,"]/_/g;

    eval {$json = decode_json($data[1]);1;};
    if ($@) {
      Log3 $bname, 2, "$btype $name: WARNING: deformed JSON data, check your ESP config ($peer)";
      Log3 $bname, 2, "$btype $name: $@";
     return;
    }

    # check that ESPEasy software is new enough
    return if ESPEasy_checkVersion($bhash,$peer,$json->{data}{ESP}{build},$json->{version});

    # should never happen, but who knows what some JSON module versions do...
    $json->{data}{ESP}{name} = "" if !defined $json->{data}{ESP}{name};
    $json->{data}{SENSOR}{0}{deviceName} = "" if !defined $json->{data}{SENSOR}{0}{deviceName};
    
    # remove illegal chars from ESP name for further processing and assign to new var
    (my $espName = $json->{data}{ESP}{name}) =~ s/[^A-Za-z\d_\.]/_/g;
    (my $espDevName = $json->{data}{SENSOR}{0}{deviceName}) =~ s/[^A-Za-z\d_\.]/_/g;

    # check that 'ESP name' or 'device name' is set
    if ($espName eq "" && $espDevName eq "") {
      Log3 $bname, 2, "$btype $name: WARNIING 'ESP name' and 'device name' "
                     ."missing ($peer). Check your ESP config. Skip processing data.";
      Log3 $bname, 2, "$btype $name: Data: $data[1]";
      return;
    }

    # deprecated
    # check that 'device name' is set at least if uniqIDs is disabled
    if (!AttrVal($bname,"uniqIDs",1) && $espDevName eq "") {
      Log3 $bname, 2, "$btype $name: WARNIING 'device name' missing ($peer). "
                     ."Check your ESP config or enable uniqIDs. "
                     ."Skip processing data.";
      Log3 $bname, 2, "$btype $name: Data: $data[1]";
      return;
    }

    my $ident;

    # deprecated
    if(!AttrVal($bname,"uniqIDs",1)) {
      $ident = $espDevName
    }

    $ident = ESPEasy_isCombineDevices($peer,$espName,AttrVal($bname,"combineDevices",0))
      ? $espName ne "" ? $espName : $peer
      : $espName.($espName ne "" && $espDevName ne "" ? "_" : "").$espDevName;

    # push internals in @values (and in bridge helper for support reason, only)
    my @values;
    my @intVals = qw(unit sleep build);
    foreach my $intVal (@intVals) {
      push(@values,"i||".$intVal."||".$json->{data}{ESP}{$intVal}."||0");
      $bhash->{helper}{received}{$peer}{$intVal} = $json->{data}{ESP}{$intVal};
    }
    $bhash->{helper}{received}{$peer}{espName} = $espName;

    # push sensor value in @values
    foreach my $vKey (keys %{$json->{data}{SENSOR}}) {
      if(ref $json->{data}{SENSOR}{$vKey} eq ref {} 
      && exists $json->{data}{SENSOR}{$vKey}{value}) {
        # remove illegal chars
        $json->{data}{SENSOR}{$vKey}{valueName} =~ s/[^A-Za-z\d_\.\-\/]/_/g;
        my $dmsg = "r||".$json->{data}{SENSOR}{$vKey}{valueName}
                   ."||".$json->{data}{SENSOR}{$vKey}{value}
                   ."||".$json->{data}{SENSOR}{$vKey}{type};
        if ($dmsg =~ m/(\|\|\|\|)|(\|\|$)/) { #detect an empty value
          Log3 $bname, 2, "$btype $name: WARNING: value name or value is "
                         ."missing ($peer). Skip processing this value.";
          Log3 $bname, 2, "$btype $name: Data: $data[1]";
          next; #skip further processing for this value only
        }
        push(@values,$dmsg);
      }
    }

    ESPEasy_dispatch($hash,$ident,$peer,@values);    

  } #$data[1] =~ m/"module":"ESPEasy"/

  else {
    Log3 $bname, 2, "$btype $name: WARNING: wrong controller configured or "
                   ."ESPEasy Version is too old.";
    Log3 $bname, 2, "$btype $name: WARNING: ESPEasy version R"
                   .$ESPEasy_minESPEasyBuild." or later required.";
  }
  
  # session will not be close immediately if ESP goes to sleep after http send
  # needs further investigation?
  if ($hash->{TEMPORARY} && $json->{data}{ESP}{sleep}) {
    CommandDelete(undef, $name);
  }
  return;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Write($$$$$@) #called from logical's IOWrite (end of SetFn)
{
  my ($hash,$ip,$port,$ident,$parseCmd,$cmd,@params) = @_;
  my ($name,$type,$self) = ($hash->{NAME},$hash->{TYPE},ESPEasy_whoami()."()");

  if ($cmd eq "cleanup") {
    delete $hash->{helper}{received}{$ip};
    return undef;
  }

  elsif ($cmd =~ "statusrequest") {
    ESPEasy_statusRequest($hash);
    return undef;
  }
  
  ESPEasy_httpRequest($hash, $ip, $port, $ident, $parseCmd, $cmd, @params);
}


# ------------------------------------------------------------------------------
sub ESPEasy_Notify($$)
{
  my ($hash,$dev) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};

  # $hash->{NOTIFYDEV} = "global" set in DefineFn
  return if(!grep(m/^(DELETE)?ATTR $name /, @{$dev->{CHANGED}}));

  foreach (@{$dev->{CHANGED}}) {
    if (m/^(DELETE)?ATTR ($name) (\w+)\s?(\d+)?$/) {
      Log3 $name, 5, "$type $name: received event: $_";

      if ($3 eq "disable") {
        if (defined $1 || (defined $4 && $4 eq "0")) {
          Log3 $name, 4,"$type $name: Device enabled";
          ESPEasy_resetTimer($hash) if ($hash->{SUBTYPE} eq "device");
          readingsSingleUpdate($hash, 'state', 'opened',1);
        }
        else {
          Log3 $name, 3,"$type $name: Device disabled";
          ESPEasy_clearReadings($hash) if $hash->{SUBTYPE} eq "device";
          ESPEasy_resetTimer($hash,"stop");
          readingsSingleUpdate($hash, "state", "disabled",1)
        }
      }

      elsif ($3 eq "Interval") {
        if (defined $1) {
          $hash->{INTERVAL} = $dInterval;
        }
        elsif (defined $4 && $4 eq "0") {
          $hash->{INTERVAL} = "disabled";
          ESPEasy_resetTimer($hash,"stop");
          CommandDeleteReading(undef, "$name presence") 
            if defined $hash->{READINGS}{presence};
        }
        else { # Interval > 0
          $hash->{INTERVAL} = $4;
          ESPEasy_resetTimer($hash);
        }
      }

      elsif ($3 eq "setState") {
        if (defined $1 || (defined $4 && $4 > 0)) {
          ESPEasy_setState($hash);
        }
        else { #setState == 0
          CommandSetReading(undef,"$name state opened");
        }
      }
      
      else {
        #Log 5, "$type $name: Attribute $3 not handeled by NotifyFn ";      
      }

    } #main if
    else { #should never be reached
      #Log 5, "$type $name: WARNING: unexpected event received by NotifyFn: $_";
    }
  }
  
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Rename() {
	my ($new,$old) = @_;
  my $i = 0;
	my $type    = $defs{"$new"}->{TYPE};
	my $name    = $defs{"$new"}->{NAME};
	my $subtype = $defs{"$new"}->{SUBTYPE};
  my @am;

  # copy values from old to new device
	setKeyValue($type."_".$new."-user",getKeyValue($type."_".$old."-user"));
	setKeyValue($type."_".$new."-pass",getKeyValue($type."_".$old."-pass"));
	setKeyValue($type."_".$new."-firstrun",getKeyValue($type."_".$old."-firstrun"));

  # delete old entries
	setKeyValue($type."_".$old."-user",undef);
	setKeyValue($type."_".$old."-pass",undef);
	setKeyValue($type."_".$old."-firstrun",undef);

  # replace IDENT in devices if bridge name changed
  if ($subtype eq "bridge") {
    foreach my $ldev (devspec2array("TYPE=$type")) {
      my $dhash = $defs{$ldev};
      my $dsubtype = $dhash->{SUBTYPE};
      next if ($dsubtype eq "bridge");
      my $dname = $dhash->{NAME};
      my $ddef  = $dhash->{DEF};
      my $oddef = $dhash->{DEF};
      $ddef =~ s/ $old / $new /;
      if ($oddef ne $ddef){
        $i = $i+2;
        CommandModify(undef, "$dname $ddef");
        CommandAttr(undef,"$dname IODev $new");
        push (@am,$dname);
      }
    }
  }
  Log3 $name, 2, "$type $name: Device $old renamed to $new";
  Log3 $name, 2, "$type $name: Attribute IODev set to '$name' in these "
                ."devices: ".join(", ",@am) if $subtype eq "bridge";

  if (AttrVal($name,"autosave",AttrVal("global","autosave",1)) && $i>0) {
    CommandSave(undef,undef);
    Log3 $type, 2, "$type $name: $i structural changes saved "
                  ."(autosave is enabled)";
  }
  elsif ($i>0) {
    Log3 $type, 2, "$type $name: There are $i structural changes. "
                  ."Don't forget to save chages.";
  }

	return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Attr(@)
{
  my ($cmd,$name,$aName,$aVal) = @_;
  my $hash = $defs{$name};
  my $type = $hash->{TYPE};
  my $ret;

  if ($cmd eq "set" && !defined $aVal) {
    Log3 $name, 2, "$type $name: attr $name $aName '': value must not be empty";
    return "$name: attr $aName: value must not be empty";
  }
  
  # device attributes
  if (defined $hash->{SUBTYPE} && $hash->{SUBTYPE} eq "bridge" 
  && ($aName =~ /(^Interval|pollGPIOs|IODev|setState|readingSwitchText)$/
  ||  $aName =~ /^(readingPrefixGPIO|readingSuffixGPIOState|adjustValue)$/
  ||  $aName =~ /^(presenceCheck|parseCmdResponse)$/)) {
    Log3 $name, 2, "$type $name: Attribut '$aName' can not be used by bridge";
    return "$type: attribut '$aName' cannot be used by bridge device";  
  }
  # bridge attributes
  elsif (defined $hash->{SUBTYPE} && $hash->{SUBTYPE} eq "device"
  && ($aName =~ /^(autocreate|autosave|authentication|httpReqTimeout)$/
  ||  $aName =~ /^(allowedIPs|deniedIPs|combineDevices)$/ )) {
    Log3 $name, 2, "$type $name: Attribut '$aName' can be used with "
                  ."bridge device, only";
    return "$type: attribut '$aName' can be used with the bridge device, only";
  }

  elsif ($aName =~ /^autosave|autocreate|authentication|disable$/
      || $aName =~ /^presenceCheck|readingSwitchText$/) {
    $ret = "0,1" if ($cmd eq "set" && not $aVal =~ m/^(0|1)$/)}

  elsif ($aName =~ /^uniqIDs$/) {
    if ($cmd eq "set" && not $aVal =~ m/^(0|1)$/) {
      $ret = "0,1" 
    }
    elsif ($cmd eq "set" && $aVal eq "0") {
      Log3 $name, 1, $type.':';
      Log3 $name, 1, $type.': __        ___    ____  _   _ ___ _   _  ____ ';
      Log3 $name, 1, $type.': \ \      / / \  |  _ \| \ | |_ _| \ | |/ ___|';
      Log3 $name, 1, $type.':  \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _ ';
      Log3 $name, 1, $type.':   \ V  V / ___ \|  _ <| |\  || || |\  | |_| |';
      Log3 $name, 1, $type.':    \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____|';
      Log3 $name, 1, $type.':';
      Log3 $name, 1, "$type $name: Attribut $aName is deprecated and will be "
                    ."removed from next release. Please update your config soon.";
      Log3 $name, 1, "$type $name: Use attribute combineDevices instead.";
                 
      Log3 $name, 1, $type.':';
      $hash->{WARNING} = "Attribute $aName is deprecated and will be removed soon!";
    } }    

  elsif ($aName eq "combineDevices") {
    $ret = "0 | 1 | ESPname | ip[/netmask][,ip[/netmask]][,...]" 
      if $cmd eq "set" && !(ESPEasy_isAttrCombineDevices($aVal) || $aVal =~ m/^[01]$/ )}
      
  elsif ($aName =~ /^(allowedIPs|deniedIPs)$/) {
    $ret = "ip[/netmask][,ip[/netmask]][,...]" 
      if $cmd eq "set" && !ESPEasy_isIPv64Range($aVal)}
      
  elsif ($aName eq "pollGPIOs") {
    $ret = "GPIO_No[,GPIO_No][...]"
      if $cmd eq "set" && $aVal !~ /^[a-zA-Z]{0,2}[0-9]+(,[a-zA-Z]{0,2}[0-9]+)*$/}

  elsif ($aName eq "parseCmdResponse") {
    my $cmds = lc join("|",keys %ESPEasy_setCmdsUsage);
    $ret = "cmd[,cmd][...]" 
      if $cmd eq "set" && lc($aVal) !~ /^($cmds){1}(,($cmds))*$/}

  elsif ($aName eq "setState") {
    $ret = "integer" 
      if ($cmd eq "set" && not $aVal =~ m/^(\d+)$/)}

  elsif ($aName eq "readingPrefixGPIO") {
    $ret = "[a-zA-Z0-9._-/]+"
      if ($cmd eq "set" && $aVal !~ m/^[A-Za-z\d_\.\-\/]+$/)}

  elsif ($aName eq "readingSuffixGPIOState") {
    $ret = "[a-zA-Z0-9._-/]+"
      if ($cmd eq "set" && $aVal !~ m/^[A-Za-z\d_\.\-\/]+$/)}

  elsif ($aName eq "httpReqTimeout") {
    $ret = "3..60"
      if $cmd eq "set" && ($aVal < 3 || $aVal > 60)}
      
  elsif ($aName eq "Interval") {
    ($cmd eq "set" && ($aVal !~ m/^(\d)+$/ || $aVal <10 && $aVal !=0))
      ? $ret = "0 or >=10" 
      : $hash->{INTERVAL} = $aVal}

  if (!$init_done) {
    if ($aName =~ /^disable$/ && $aVal == 1) {
      readingsSingleUpdate($hash, "state", "disabled",1);
    }
  }

  if (defined $ret) {
    Log3 $name, 2, "$type $name: attr $name $aName '$aVal' != '$ret'";
    return "$name: $aName must be: $ret";
  }

  return undef;
}


# ------------------------------------------------------------------------------
#UndefFn: called while deleting device (delete-command) or while rereadcfg
sub ESPEasy_Undef($$)
{
  my ($hash, $arg) = @_;
  my ($name,$type,$port) = ($hash->{NAME},$hash->{TYPE},$hash->{PORT});

  # close server and return if it is a child process for incoming http requests
  if (defined $hash->{TEMPORARY} && $hash->{TEMPORARY} == 1) {
    my $bhash = $modules{ESPEasy}{defptr}{BRIDGE};
    Log3 $bhash->{NAME}, 4, "$type $name: Closing tcp session.";
    TcpServer_Close($hash);
    return undef   
  };

  HttpUtils_Close($hash);
  RemoveInternalTimer($hash);
  
  if($hash->{SUBTYPE} && $hash->{SUBTYPE} eq "bridge") {
    delete $modules{ESPEasy}{defptr}{BRIDGE} 
      if(defined($modules{ESPEasy}{defptr}{BRIDGE}));
    TcpServer_Close( $hash );
    Log3 $name, 2, "$type $name: Socket on port tcp/$port closed";
  }
  else {
    IOWrite($hash, $hash->{HOST}, undef, undef, undef, "cleanup", undef );
  }
  
  return undef;
}


# ------------------------------------------------------------------------------
#ShutdownFn: called before fhem's shutdown command
sub ESPEasy_Shutdown($)
{
  my ($hash) = @_;
  HttpUtils_Close($hash);
  Log3 $hash->{NAME}, 4, "$hash->{TYPE} $hash->{NAME}: Shutdown requested";
  return undef;
}


# ------------------------------------------------------------------------------
#DeleteFn: called while deleting device (delete-command) but after UndefFn
sub ESPEasy_Delete($$)
{
  my ($hash, $arg) = @_;
  #return if it is a child process for incoming http requests
  if (not defined $hash->{TEMPORARY}) {
    setKeyValue($hash->{TYPE}."_".$hash->{NAME}."-user",undef);
    setKeyValue($hash->{TYPE}."_".$hash->{NAME}."-pass",undef);
    setKeyValue($hash->{TYPE}."_".$hash->{NAME}."-firstrun",undef);

    Log3 $hash->{NAME}, 4, "$hash->{TYPE} $hash->{NAME}: $hash->{NAME} deleted";
  }
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_dispatch($$$@) #called by bridge -> send to logical devices
{
  my($hash,$ident,$host,@values) = @_;
  my $name = $hash->{NAME};
  return if (IsDisabled $name);  

  my $type = $hash->{TYPE};
  my $bhash = $modules{ESPEasy}{defptr}{BRIDGE};
  my $bname = $bhash->{NAME};

  my $ui = (AttrVal($bname,"uniqIDs",1)) ? 1 : 0;
  my $as = (AttrVal($bname,"autosave",AttrVal("global","autosave",1))) ? 1 : 0;
  my $ac = (AttrVal($bname,"autocreate",AttrVal("global","autoload_undefined_devices",1))) ? 1 : 0;
  my $msg = $ident."::".$host."::".$ac."::".$as."::".$ui."::".join("|||",@values);

  Log3 $bname, 5, "$type $name: Dispatch: $msg";
  Dispatch($bhash, $msg, undef);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_dispatchParse($$$) # called by logical device (defined by 
{                              # $hash->{ParseFn})
  # we are called from dispatch() from the ESPEasy bridge device
  # we never come here if $msg does not match $hash->{MATCH} in the first place
  my ($IOhash, $msg) = @_;   # IOhash points to the ESPEasy bridge, not device
  my $IOname = $IOhash->{NAME};
  my $type   = $IOhash->{TYPE};

  # 1:ident 2:ip 3:autocreate 4:autosave 5:uniqIDs 6:value(s)
  my ($ident,$ip,$ac,$as,$ui,$v) = split("::",$msg);
  return undef if !$ident || $ident eq "";

  my $name;
  my @v = split("\\|\\|\\|",$v);
    
  # look in each $defs{$d}{IDENT} for $ident to get device name.
  foreach my $d (keys %defs) {
    next if($defs{$d}{TYPE} ne "ESPEasy");
    if (InternalVal($defs{$d}{NAME},"IDENT","") eq "$ident") {
      $name = $defs{$d}{NAME} ;
      last;
    }
  }

  # autocreate device if no device has $ident asigned.
  if (!($name) && $ac eq "1") {
    $name = ESPEasy_autocreate($IOhash,$ident,$ip,$as);
    # cleanup helper
    delete $IOhash->{helper}{autocreate}{$ip}{$ident} 
      if defined $IOhash->{helper}{autocreate}{$ip}{$ident};
    delete $IOhash->{helper}{autocreate}{$ip}
      if scalar keys %{$IOhash->{helper}{autocreate}{$ip}} == 0;
    delete $IOhash->{helper}{autocreate}
      if scalar keys %{$IOhash->{helper}{autocreate}} == 0;
  }
  # autocreate is disabled
  elsif (!($name) && $ac eq "0") {
    Log3 $IOname, 2, "$type $IOname: autocreate is disabled (ident: $ident)"
      if not defined $IOhash->{helper}{autocreate}{$ip}{$ident};
    $IOhash->{helper}{autocreate}{$ip}{$ident} = "disabled";
    return $ident;
  }
  
  return $name if (IsDisabled $name);
  my $hash = $defs{$name};

  Log3 $name, 5, "$type $name: Received: $msg";

  if (defined $hash && $hash->{TYPE} eq "ESPEasy" && $hash->{SUBTYPE} eq "device") {
    $hash->{UNIQIDS} = $ui;
    my @logInternals;
    foreach (@v) {
      my ($cmd,$reading,$value,$vType) = split("\\|\\|",$_);

      # reading prefix replacement (useful if we poll values)
      my $replace = '"'.AttrVal($name,"readingPrefixGPIO","GPIO").'"';
      $reading =~ s/^GPIO/$replace/ee;

      # --- setReading ----------------------------------------------
      if ($cmd eq "r") { 
        # reading suffix replacement only for setreading
        $replace = '"'.AttrVal($name,"readingSuffixGPIOState","").'"';
        $reading =~ s/_state$/$replace/ee;

        # map value to on/off if device is a switch
        $value = ($value eq "1") ? "on" : "off" 
          if ($vType == 10 && AttrVal($name,"readingSwitchText",1) 
          && $value =~ /^(0|1)$/);

        # attr adjustValue
        $value = ESPEasy_adjustValue($hash,$reading,$value);

        readingsSingleUpdate($hash, $reading, $value, 1);
        Log3 $name, 4, "$type $name: $reading: $value";

        # used for presence detection
        $hash->{helper}{received}{$reading} = $ip;

        if (exists ($hash->{"WARNING_$ip"})) {
          if (defined $hash->{"WARNING_$ip"}) {
            Log3 $name, 2, "$type $name: RESOLVED: ".$hash->{"WARNING_$ip"};
          }
          delete $hash->{"WARNING_$ip"};
        }

      }

      # --- setInternal ---------------------------------------------
      elsif ($cmd eq "i") {
        $hash->{helper}{internals}{$ip}{uc($reading)} = $value;
        push(@logInternals,"$reading:$value");
      }

      # --- Error ---------------------------------------------------
      elsif ($cmd eq "e") {
        if (!defined $hash->{"WARNING_$ip"} || $hash->{"WARNING_$ip"} ne $value) {
          Log3 $name, 2, "$type $name: WARNING: $value";
          $hash->{"WARNING_$ip"} = $value;
        }
        #readingsSingleUpdate($hash, $reading, $value, 1);
      }

      # --- DeleteReading -------------------------------------------
      elsif ($cmd eq "dr") {
        CommandDeleteReading(undef, "$name $reading");
        Log3 $name, 4, "$type $name: Reading $reading deleted";
      }
      
      else {
        Log3 $name, 2, "$type $name: Unknown command received via dispatch";
      }
    } # foreach @v

    Log3 $name, 5, "$type $name: Internals: ".join(" ",@logInternals)
      if scalar @logInternals > 0;
    ESPEasy_setESPConfig($hash);
    ESPEasy_checkPresence($hash,$ip);
    ESPEasy_setState($hash);

  }

  else { #autocreate failed
    Log3 undef, 2, "ESPEasy: Device $name not defined";
  }
 
  return $name;  # must be != undef. else msg will processed further -> help me!
}


# ------------------------------------------------------------------------------
sub ESPEasy_autocreate($$$$)
{
  my ($IOhash,$ident,$ip,$autosave) = @_;
  my $IOname = $IOhash->{NAME};
  my $IOtype = $IOhash->{TYPE};

  my $devname = "ESPEasy_".$ident;
  my $define  = "$devname ESPEasy $ip 80 $IOhash->{NAME} $ident";
  Log3 undef, 2, "$IOtype $IOname: Autocreate $define";

  my $cmdret= CommandDefine(undef,$define);
  if(!$cmdret) {
    $cmdret= CommandAttr(undef, "$devname room $IOhash->{TYPE}");
    $cmdret= CommandAttr(undef, "$devname group $IOhash->{TYPE} Device");
    $cmdret= CommandAttr(undef, "$devname setState 3");
    $cmdret= CommandAttr(undef, "$devname Interval $dInterval");
    $cmdret= CommandAttr(undef, "$devname presenceCheck 1");
    $cmdret= CommandAttr(undef, "$devname readingSwitchText 1");
    if (AttrVal($IOname,"autosave",AttrVal("global","autosave",1))) {
      CommandSave(undef,undef);
      Log3 undef, 2, "$IOtype $IOname: Structural changes saved.";
    } 
    else {
      Log3 undef, 2, "$IOtype $IOname: Autosave is disabled: "
                    ."Do not forget to save changes.";
    }
  }
  else {
    Log3 undef, 1, "$IOtype $IOname: WARNING: an error occurred "
                  ."while creating device for $ident: $cmdret";
  } 

  return $devname;
}


# ------------------------------------------------------------------------------
sub ESPEasy_httpRequest($$$$$$@)
{
  my ($hash, $host, $port, $ident, $parseCmd, $cmd, @params) = @_;
  my ($name,$type,$self) = ($hash->{NAME},$hash->{TYPE},ESPEasy_whoami()."()");
  my $orgParams = join(",",@params);
  my $orgCmd = $cmd;

#  Log3 $name, 5, "$type $name: httpRequest(ip:$host, port:$port, ident:$ident,"
#                ." cmd:$cmd, params:$orgParams)";

  # raw is used for command not implemented right now
  if ($cmd eq "raw") {
    $cmd = $params[0];
    splice(@params,0,1);
  }

  $params[0] = ",".$params[0] if $params[0];
  my $plist = join(",",@params);

  my $url = "http://".$host.":".$port."/control?cmd=".$cmd.$plist;
  
  # there is already a log entry with verbose 3 from device
  Log3 $name, 4, "$type $name: Send $cmd$plist to $host for ident $ident" if ($cmd !~ /^(status)/);


  my $timeout = AttrVal($name,"httpReqTimeout",$dhttpReqTimeout);
  my $httpParams = {
    url         => $url,
    timeout     => $timeout,
    keepalive   => 0,
    httpversion => "1.0",
    hideurl     => 0,
    method      => "GET",
    hash        => $hash,      # passthrought to parseFn
    cmd         => $orgCmd,    # passthrought to parseFn
    plist       => $orgParams, # passthrought to parseFn
    host        => $host,      # passthrought to parseFn
    port        => $port,      # passthrought to parseFn
    ident       => $ident,     # passthrought to parseFn
    parseCmd    => $parseCmd,  # passthrought to parseFn (attr parseCmdResponse => (0)|1)
    callback    =>  \&ESPEasy_httpRequestParse
  };
  Log3 $name, 5, "$type $name: NonblockingGet for ident:$ident => $url";
  HttpUtils_NonblockingGet($httpParams);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_httpRequestParse($$$)
{
  my ($param, $err, $data) = @_;
  my $hash = $param->{hash};
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});
  my @values;
  
  if ($err ne "") {
   #Log3 $name, 2, "$type $name: WARNING for ident:$param->{ident} "
   #              ."cmd:'$param->{cmd},$param->{plist}' => $err";
    @values = ("e||_lastError||$err||0");
  }

  elsif ($data ne "") { # no error occurred
  
    # check that response from cmd should be parsed (client attr parseCmdResponse)
    return undef if (!$param->{parseCmd});

    (my $logData = $data) =~ s/\n//sg;
    Log3 $name, 5, "$type $name: http response for ident:$param->{ident} "
                  ."cmd:'$param->{cmd},$param->{plist}' => '$logData'";
    if ($data =~ /^{/) { #it could be json...
      my $res;
      eval {$res = decode_json($data);1;};
      if ($@) {
        Log3 $name, 2, "$type $name: WARNING: deformed JSON data received "
                      ."from $param->{host} requested by $param->{ident}.";
        Log3 $name, 2, "$type $name: $@";
        @values = ("e||_lastError||$@||0");
        return undef;
      }

      # maps plugin type (answer for set state/gpio) to SENSOR_TYPE_SWITCH
      # 10 = SENSOR_TYPE_SWITCH
      my $vType = (defined $res->{plugin} && $res->{plugin} eq "1") ? "10" : "0";

      # push values/cmds in @values
      push @values, "r||GPIO".$res->{pin}."_mode||".$res->{mode}."||".$vType;
      push @values, "r||GPIO".$res->{pin}."_state||".$res->{state}."||".$vType;
      push @values, "r||_lastAction"."||".$res->{log}."||".$vType if $res->{log} ne "";
    } #it is json...

    else { # no json returned => unknown state
      Log3 $name, 5, "$type $name: No json fmt: ident:$param->{ident} ".
                     "$param->{cmd}$param->{plist} => $data";
    return undef;
    }
  } # ($data ne "") 
  
  ESPEasy_dispatch($hash,$param->{ident},$param->{host},@values);
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_statusRequest($) #called by device
{
  my ($hash) = @_;
  my ($name, $type) = ($hash->{NAME},$hash->{TYPE});

  unless (IsDisabled $name) {
    Log3 $name, 4, "$type $name: set statusRequest";
    ESPEasy_pollGPIOs($hash);
    ESPEasy_checkPresence($hash);
    ESPEasy_setState($hash);
  }
  ESPEasy_resetTimer($hash);
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_pollGPIOs($) #called by device
{
  my ($hash) = @_;
  my $name  = $hash->{NAME};
  my $type  = $hash->{TYPE};

  my $sleep = $hash->{helper}{internals}{$hash->{HOST}}{SLEEP};
  my $a = AttrVal($name,'pollGPIOs',undef);

  if (!defined $a) {
    # do nothing, just return
  }
  elsif (defined $hash->{UNIQIDS} && $hash->{UNIQIDS} == 0) {
    Log3 $name, 1, "$type $name: Polling of GPIOs is not possible as long as uniqIDs are disabled.";
  }
  elsif (defined $sleep && $sleep eq "1") {
    Log3 $name, 1, "$type $name: Polling of GPIOs is not possible as long as deep sleep mode is active.";
  }

  else {
    my @gpios = split(",",$a);
    foreach my $gpio (@gpios) {
      if ($gpio =~ /^[a-zA-Z]/) { # pin mapping (eg. D8 -> 15)
        Log3 $name, 5, "$type $name: Pin mapping ".uc $gpio." => $ESPEasy_pinMap{uc $gpio}";
        $gpio = $ESPEasy_pinMap{uc $gpio};
      }
      Log3 $name, 5, "$type $name: IOWrite(\$defs{$name}, $hash->{HOST}, $hash->{PORT}, $hash->{IDENT}, 1, status, gpio,".$gpio.")";
      IOWrite($hash, $hash->{HOST}, $hash->{PORT}, $hash->{IDENT}, 1, "status", "gpio,".$gpio);
    } #foreach
  } #else

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_resetTimer($;$)
{
  my ($hash,$sig) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};
  $sig = "" if !$sig;

  if ($init_done == 1) {
    #Log3 $name, 5, "$type $name: RemoveInternalTimer ESPEasy_statusRequest";
    RemoveInternalTimer($hash, "ESPEasy_statusRequest");
    delete $hash->{helper}{intAt};
  }
  
  if ($sig eq "stop") {
    Log3 $name, 5, "$type $name: internalTimer stopped";
    return undef;
  }
  return undef if AttrVal($name,"Interval",$dInterval) == 0;
    
  unless(IsDisabled($name)) {
    my $s  = AttrVal($name,"Interval",$dInterval) + rand(5);
    my $ts = $s + gettimeofday();
    Log3 $name, 5, "$type $name: Start internalTimer +".int($s)." => ".FmtDateTime($ts);
    InternalTimer($ts, "ESPEasy_statusRequest", $hash);
    ESPEasy_intAt2helper($hash);
  }

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_intAt2helper($) {
  my ($hash) = @_;

  my $i = 1;
  delete $hash->{helper}{intAt};
  foreach my $a (keys %intAt) {
    my $arg = $intAt{$a}{ARG};
    my $nam = (ref($arg) eq "HASH" ) ? $arg->{NAME} : "";
    if (defined $nam && $nam eq $hash->{NAME}) {
      $hash->{helper}{intAt}{$i}{TRIGGERTIME} = strftime('%d.%m.%Y %H:%M:%S',
                                            localtime($intAt{$a}{TRIGGERTIME}));
      $hash->{helper}{intAt}{$i}{INTERVAL} = round($intAt{$a}{TRIGGERTIME}-time(),0);
      $hash->{helper}{intAt}{$i}{FN} = $intAt{$a}{FN};
      $i++
    }
  }
}


# ------------------------------------------------------------------------------
sub ESPEasy_tcpServerOpen($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};
  my $port = ($hash->{PORT}) ? $hash->{PORT} : 8383;

  my $ret = TcpServer_Open( $hash, $port, "global" );
  exit(1) if ($ret && !$init_done);
  readingsSingleUpdate ( $hash, "state", "initialized", 1 );
    
  return $ret;
}


# ------------------------------------------------------------------------------
sub ESPEasy_header2Hash($) {
  my ($string) = @_;
  my %header = ();

  foreach my $line (split("\r\n", $string)) {
    my ($key,$value) = split(": ", $line,2);
    next if !$value;

    $value =~ s/^ //;
    $header{$key} = $value;
  }     
        
  return \%header;
}


# ------------------------------------------------------------------------------
sub ESPEasy_isAuthenticated($$)
{
  my ($hash,$ah) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});

  my $bhash = $modules{ESPEasy}{defptr}{BRIDGE};
  my ($bname,$btype) = ($bhash->{NAME},$bhash->{TYPE});

  my $u = getKeyValue($btype."_".$bname."-user");
  my $p = getKeyValue($btype."_".$bname."-pass");
  my $attr = AttrVal($bname,"authentication",0);

  if (!defined $u || !defined $p || $attr == 0) {
    if (defined $ah){
      Log3 $bname, 2, "$type $name: No basic authentication active but ".
                     "credentials received";
    }
    else {
       Log3 $bname, 4, "$type $name: No basic authentication required";
    }
    return "not required";
  }

  elsif (defined $ah) {
    my ($a,$v) = split(" ",$ah);
    if ($a eq "Basic" && decode_base64($v) eq $u.":".$p) {
      Log3 $bname, 4, "$type $name: Basic authentication accepted";
      return "accepted";
    }
    else {
      Log3 $bname, 2, "$type $name: Basic authentication rejected";
    }
  }

  else {
    Log3 $bname, 2, "$type $name: Basic authentication active but ".
                   "no credentials received";
  }

return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_isParseCmd($$) #called by device
{
  my ($hash,$cmd) = @_;
  my $name = $hash->{NAME};
  my $doParse = 0;

  my @cmds = split(",",AttrVal($name,"parseCmdResponse","status"));
  foreach (@cmds) {
    if (lc($_) eq lc($cmd)) {
      $doParse = 1;
      last;
    }
  }
  return $doParse;
}


# ------------------------------------------------------------------------------
sub ESPEasy_sendHttpClose($$$) {
  my ($hash,$code,$response) = @_;
  my ($name,$type,$con) = ($hash->{NAME},$hash->{TYPE},$hash->{CD});
  
  my $bhash = $modules{ESPEasy}{defptr}{BRIDGE};
  my $bname = $bhash->{NAME};
  
  print $con "HTTP/1.1 ".$code."\r\n",
         "Content-Type: text/plain\r\n",
         "Connection: close\r\n",
         "Content-Length: ".length($response)."\r\n\r\n",
         $response;
  Log3 $bname, 4, "$type $name: Send http close '$code'";
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_paramPos($$)
{
  my ($cmd,$search) = @_;
  my @usage = split(" ",$ESPEasy_setCmdsUsage{$cmd});
  my $pos = 0;
  my $i = 0;

  foreach (@usage) {
    if ($_ eq $search) {
      $pos = $i;
      last;
    }
    $i++;
  }
  
  return $pos; # return 0 if no match, else position
}


# ------------------------------------------------------------------------------
sub ESPEasy_paramCount($) 
{ 
  return () = $_[0] =~ /\s/g  # count \s in a string
}


# ------------------------------------------------------------------------------
sub ESPEasy_clearReadings($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};

  my @dr;
  foreach (keys %{$hash->{READINGS}}) {
#    next if $_ =~ m/^(presence)$/;
    CommandDeleteReading(undef, "$name $_"); 
#    fhem("deletereading $name $_");
    push(@dr,$_);
  }

  if (scalar @dr >= 1) {
    delete $hash->{helper}{received};
    delete $hash->{helper}{presence};
    delete $hash->{helper}{internals};
    delete $hash->{ESP_CONFIG};
    Log3 $name, 3, "$type $name: Readings [".join(",",@dr)."] wiped out";
  }

  ESPEasy_setState($hash);

  return undef
}


# ------------------------------------------------------------------------------
sub ESPEasy_checkVersion($$$$)
{
  my ($hash,$dev,$ve,$vj) = @_;
  my ($type,$name) = ($hash->{TYPE},$hash->{NAME});
  my $ov = "_OUTDATED_ESP_VER_$dev";

  if ($vj < $ESPEasy_minJsonVersion) {
    $hash->{$ov} = "R".$ve."/J".$vj;
    Log3 $name, 2, "$type $name: WARNING: no data processed. ESPEasy plugin "
                  ."'FHEM HTTP' is too old [$dev: R".$ve." J".$vj."]. ".
                   "Use ESPEasy R$ESPEasy_minESPEasyBuild at least.";
  return 1;
  } 
  else{
    delete $hash->{$ov} if exists $hash->{$ov};
    return 0;
  }
}


# ------------------------------------------------------------------------------
sub ESPEasy_checkPresence($;$)
{
  my ($hash,$host) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};
  my $interval = AttrVal($name,'Interval',$dInterval);
  my $addTime = 3; # if there is extreme heavy system load

  if (defined $host) {
    $hash->{helper}{presence}{$host} = "present";
  }

  return undef if AttrVal($name,'presenceCheck',1) == 0;
  return undef if $interval == 0;
  ###
  # update presence only if 1st check was $interval seconds ago.
  $hash->{helper}{firstPresenceCheck} = time() if (!defined $hash->{helper}{firstPresenceCheck});
  return undef if ((time() - $hash->{helper}{firstPresenceCheck}) <= $interval);
  ###

  # check each received ip
  foreach my $ip (keys %{$hash->{helper}{presence}}) {
    $hash->{helper}{presence}{$ip} = "absent";
    # check each received reading
    foreach my $reading (keys %{$hash->{helper}{received}}) {
      next if $hash->{helper}{received}{$reading} ne $ip;
      if (ReadingsAge($name,$reading,0) < $interval+$addTime) {
        #dev is present if any reading is newer than INTERVAL+$addTime
        $hash->{helper}{presence}{$ip} = "present";
        last;
      }
    }
  }

  ###  
  # no values received within $interval for no ip
  if (!scalar keys %{$hash->{helper}{presence}}) {
    #event-on-change-reading only
    if (ReadingsVal($name,"presence","unknown") ne "absent") {
      readingsSingleUpdate($hash,"presence","absent",1);
      Log3 $name, 4, "$type $name: presence: absent";
    }
  }

  # at least 1 value was received since last restart
  else {  
  ###
    my $presence; my @ad;
    my $i = 0; my $p = 0;
    foreach my $ip (keys %{$hash->{helper}{presence}}) {
      if ($hash->{helper}{presence}{$ip} eq "absent") {
        push(@ad,$ip); 
        $p++;
      }
      $i++
    }
    if    ($p == 0)  {$presence = "present"}
    elsif ($p == $i) {$presence = "absent"}
    else             {$presence = "partial absent (".join(",",@ad).")"}

    #event-on-change-reading only
    if ($presence ne ReadingsVal($name,"presence","unknown")) {
      readingsSingleUpdate($hash,"presence",$presence,1);
      Log3 $name, 4, "$type $name: presence: $presence";
    }

  ###
  } # else (!scalar keys %{$hash->{helper}{presence}})
  ###

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_setESPConfig($)
{
  my ($hash) = @_;
 
  my @config;
  foreach my $ip (sort keys %{$hash->{helper}{internals}}) {
    my @v;
    foreach my $internal (sort keys %{$hash->{helper}{internals}{$ip}}) {
      push(@v,substr($internal,0,1).$hash->{helper}{internals}{$ip}{$internal});
    }
    push(@config,$ip.":".join(",",@v));
    s/:B/:R/ for @config; #just cosmetically 
  }
  $hash->{ESP_CONFIG} = join(" | ",@config);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_setState($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};
  return undef if not AttrVal($name,"setState",1);
  my $interval = AttrVal($name,"Interval",$dInterval);
  my $addTime = 3;

  my @ret;
  foreach my $reading (sort keys %{$hash->{helper}{received}}) {
    next if $reading =~ /^(state|presence|_lastAction|_lastError|\w+_mode)$/;
    next if $interval && ReadingsAge($name,$reading,1) > $interval+$addTime;
    push(@ret, substr($reading,0,AttrVal($name,"setState",3))
              .": ".ReadingsVal($name,$reading,""));
  }

  my $oState = ReadingsVal($name, "state", "");
  my $presence = ReadingsVal($name, "presence", "opened");

  if ($presence eq "absent" && $oState ne "absent") {
    readingsSingleUpdate($hash,"state","absent", 1 );
    delete $hash->{helper}{received};
  }
  else {
    my $nState = (scalar @ret >= 1) ? join(" ",@ret) : $presence;
    readingsSingleUpdate($hash,"state",$nState, 1 ) if ($oState ne $nState);
  }

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_adjustValue($$$)
{
  my ($hash,$r,$v) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};
 
  my $a = AttrVal($name,"adjustValue",undef);
  return $v if !defined $a;
  
  my ($VALUE,$READING,$NAME) = ($v,$r,$name); #capital vars für use in attribute
  my @a = split(" ",$a);
  foreach (@a) {
    my ($regex,$formula) = split(":",$_);
    if ($r =~ m/^$regex$/) {
      no warnings;
      my $adjVal = $formula =~ m/\$VALUE/ ? eval($formula) : eval($v.$formula);
      use warnings;
      if ($@) {
        Log3 $name, 2, "$type $name: WARNING: attribute 'adjustValue': "
                      ."mad expression '$formula'";
        Log3 $name, 2, "$type $name: $@";
      }
      else {
        Log3 $name, 4, "$type $name: Adjusted reading $r: $v => $formula = $adjVal";
        return $adjVal;
      }
      #last; #disabled to be able to match multiple readings
    }
  }
  
  return $v;
}


# ------------------------------------------------------------------------------
sub ESPEasy_isPmInstalled($$)
{
  my ($hash,$pm) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});
  if (not eval "use $pm;1")
  {
    Log3 $name, 1, "$type $name: perl modul missing: $pm. Install it, please.";
    $hash->{MISSING_MODULES} .= "$pm ";
    return "failed: $pm";
  }
  
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_isAttrCombineDevices($) 
{
  return 0 if !defined $_[0];
  my @ranges = split(/,| /,$_[0]);
  foreach (@ranges) {
    if (!($_ =~ /^([A-Za-z0-9_\.]|[A-Za-z0-9_\.][A-Za-z0-9_\.]*[A-Za-z0-9\._])$/
    || ESPEasy_isIPv64Range($_))) 
    {
      return 0 
    }
  }

  return 1;
}


# ------------------------------------------------------------------------------
# check if $peer is covered by $allowed (eg. 10.1.2.3 is included in 10.0.0.0/8)
# 1:peer address 2:allowed range
# ------------------------------------------------------------------------------
sub ESPEasy_isCombineDevices($$$)
{
  my ($peer,$espName,$allowed) = @_;
  return $allowed if $allowed =~ m/^[01]$/;
  
  my @allowed = split(/,| /,$allowed);
  foreach (@allowed) { return 1 if $espName eq $_ }
  return 1 if ESPEasy_isPeerAllowed($peer,$allowed);
  return 0;
}


# ------------------------------------------------------------------------------
# check param to be a valid ip64 address or fqdn or hostname
# ------------------------------------------------------------------------------
sub ESPEasy_isValidPeer($)
{
  my ($addr) = @_;
  return 0 if !defined $addr;
  my @ranges = split(/,| /,$addr);
  foreach (@ranges) {
    return 0 if !( ESPEasy_isIPv64Range($_) 
                || ESPEasy_isFqdn($_) || ESPEasy_isHostname($_) );
  }

  return 1;
}


# ------------------------------------------------------------------------------
# check if given ip or ip range is guilty 
# argument can be: 
# - ipv4, ipv4/CIDR, ipv4/dotted, ipv6, ipv6/CIDR
# - space or comma separated list of above.
# ------------------------------------------------------------------------------
sub ESPEasy_isIPv64Range($)
{
  my ($addr) = @_;
  return 0 if !defined $addr;
  my @ranges = split(/,| /,$addr);
  foreach (@ranges) {
    my ($ip,$nm) = split("/",$_);
    if (ESPEasy_isIPv4($ip)) {
      return 0 if defined $nm && !( ESPEasy_isNmDotted($nm) 
                                 || ESPEasy_isNmCIDRv4($nm) );
    }
    elsif (ESPEasy_isIPv6($ip)) {
      return 0 if defined $nm && !ESPEasy_isNmCIDRv6($nm);
    }
    else {
      return 0;
    }
  }

  return 1;
}


# ------------------------------------------------------------------------------
# check if $peer is covered by $allowed (eg. 10.1.2.3 is included in 10.0.0.0/8)
# 1:peer address 2:allowed range
# ------------------------------------------------------------------------------
sub ESPEasy_isPeerAllowed($$)
{
  my ($peer,$allowed) = @_;
  return $allowed if $allowed =~ m/^[01]$/;
  #return 1 if $allowed =~ /^0.0.0.0\/0(.0.0.0)?$/; # not necessary but faster

  my $binPeer = ESPEasy_ip2bin($peer);
  my @a = split(/,| /,$allowed);
  foreach (@a) {
    next if !ESPEasy_isIPv64Range($_);              # needed for combinedDevices
    my ($addr,$ip,$mask) = ESPEasy_addrToCIDR($_);
    return 0 if !defined $ip || !defined $mask;   # return if ip or mask !guilty
    my $binAllowed = ESPEasy_ip2bin($addr);
    my $binPeerCut = substr($binPeer,0,$mask);
    return 1 if ($binAllowed eq $binPeerCut);
  }

  return 0;
}


# ------------------------------------------------------------------------------
# convert IPv64 address to binary format and return network part of binary, only
# ------------------------------------------------------------------------------
sub ESPEasy_ip2bin($)
{
  my ($addr) = @_;
  my ($ip,$mask) = split("/",$addr);
  my @bin;

  if (ESPEasy_isIPv4($ip)) {
    $mask = 32 if !defined $mask;
    @bin = map substr(unpack("B32",pack("N",$_)),-8), split(/\./,$ip);
  }
  elsif (ESPEasy_isIPv6($ip)) {
    $ip = ESPEasy_expandIPv6($ip);
    $mask = 128 if !defined $mask;
    @bin = map {unpack('B*',pack('H*',$_))} split(/:/, $ip);
  }
  else {
    return undef;
  }

  my $bin = join('', @bin);
  my $binMask = substr($bin, 0, $mask);
 
  return $binMask; # return network part of $bin
}


# ------------------------------------------------------------------------------
# expand IPv6 address to 8 full blocks
# Advantage of IO::Socket: already installed and it is the fastest way
# http://stackoverflow.com/questions/4800691/perl-ipv6-address-expansion-parsing
# ------------------------------------------------------------------------------
sub ESPEasy_expandIPv6($)
{
  my ($ipv6) = @_;
  use Socket qw(inet_pton AF_INET6);
  return join(":", unpack("H4H4H4H4H4H4H4H4",inet_pton(AF_INET6, $ipv6)));
}


# ------------------------------------------------------------------------------
# convert IPv64 address or range into CIDR notion
# return undef if addreess or netmask is not valid
# ------------------------------------------------------------------------------
sub ESPEasy_addrToCIDR($)
{
  my ($addr) = @_;
  my ($ip,$mask) = split("/",$addr);
  # no nm specified
  return (ESPEasy_isIPv4($ip) ? ("$ip/32",$ip,32) : ("$ip/128",$ip,128)) if !defined $mask;
  # netmask is already in CIDR format and all values are valid
  return ("$ip/$mask",$ip,$mask) 
    if (ESPEasy_isIPv4($ip) && ESPEasy_isNmCIDRv4($mask)) 
    || (ESPEasy_isIPv6($ip) && ESPEasy_isNmCIDRv6($mask));
  $mask = ESPEasy_dottedNmToCIDR($mask);
  return (undef,undef,undef) if !defined $mask;

  return ("$ip/$mask",$ip,$mask);
}


# ------------------------------------------------------------------------------
# convert dotted decimal netmask to CIDR format
# return undef if nm is not in dotted decimal format
# ------------------------------------------------------------------------------
sub ESPEasy_dottedNmToCIDR($) 
{
  my ($mask) = @_;
  return undef if !ESPEasy_isNmDotted($mask);

  # dotted decimal to CIDR
  my ($byte1, $byte2, $byte3, $byte4) = split(/\./, $mask);
  my $num = ($byte1 * 16777216) + ($byte2 * 65536) + ($byte3 * 256) + $byte4;
  my $bin = unpack("B*", pack("N", $num));
  my $count = ($bin =~ tr/1/1/);

  return $count; # return number of netmask bits
}


# ------------------------------------------------------------------------------
sub ESPEasy_isIPv4($) 
{
  return 0 if !defined $_[0];
  return 1 if($_[0] 
    =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isIPv6($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] 
    =~ /^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isIPv64($)
{
  return 0 if !defined $_[0];
  return 1 if ESPEasy_isIPv4($_[0]) || ESPEasy_isIPv6($_[0]);
  return 0;
}
  
# ------------------------------------------------------------------------------
sub ESPEasy_isNmDotted($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] 
    =~ /^(255|254|252|248|240|224|192|128|0)\.0\.0\.0|255\.(255|254|252|248|240|224|192|128|0)\.0\.0|255\.255\.(255|254|252|248|240|224|192|128|0)\.0|255\.255\.255\.(255|254|252|248|240|224|192|128|0)$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isNmCIDRv4($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] =~ /^([0-2]?[0-9]|3[0-2])$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isNmCIDRv6($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] =~ /^([0-9]?[0-9]|1([0-1][0-9]|2[0-8]))$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isFqdn($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] 
    =~ /^(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)$/);
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_isHostname($)
{
  return 0 if !defined $_[0];
  return 1 if ($_[0] =~ /^([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/) 
           && !(ESPEasy_isIPv4($_[0]) || ESPEasy_isIPv6($_[0]));
  return 0;
}

# ------------------------------------------------------------------------------
sub ESPEasy_whoami()  {return (split('::',(caller(1))[3]))[1] || '';}


1;

=pod
=item device
=item summary control and access to ESP8266/ESPEasy
=item summary_DE Steuerung und Zugriff auf ESP8266/ESPEasy
=begin html

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
    <li>ESPEasy build >= R128 (self compiled) or an ESPEasy precompiled image >=
      R140_RC3<br>
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
      
    <li><a name="">user</a><br>
      returns username used by basic authentication for incoming requests.
      </li><br>

    <li><a name="">pass</a><br>
      returns password used by basic authentication for incoming requests.
      </li><br>
  </ul>

  <br><a name="ESPEasyset"></a>
  <b>Set </b>(bridge)<br><br>
  
  <ul>
    <li><a name="">help</a><br>
      Shows set command usage<br>
      required values: <code>help|pass|user</code></li><br>
      
    <li><a name="">pass</a><br>
      Specifies password used by basic authentication for incoming requests.<br>
      required value: <code>&lt;password&gt;</code><br>
      eg. : <code>set ESPBridge pass secretpass</code></li><br>
      
    <li><a name="">user</a><br>
      Specifies username used by basic authentication for incoming requests.<br>
      required value: <code>&lt;username&gt;</code><br>
      eg. : <code>set ESPBridge user itsme</code></li><br>
  </ul>

  <br><a name="ESPEasyattr"></a>
  <b>Attributes </b>(bridge)<br><br>
  
  <ul>
    <li><a name="ESPEasyallowedIPs">allowedIPs</a><br>
      Used to limit IPs or IP ranges of ESPs which are allowed to commit data.
      <br>
      Specify comma separated list of IPs or IP ranges. Netmask can be written
      as bitmask or dotted decimal. Domain names for dns lookups are not
      supported.<br>
      Possible values: IPv64 address, IPv64/netmask<br>
      Default: 0.0.0.0/0 (all IPs are allowed)<br>
      Eg. 10.68.30.147<br>
      Eg. 10.68.30.0/24,10.68.31.0/255.255.248.0<br>
      Eg. fe80::/10,2001:1a59:50a9::/48,2002:1a59:50a9::,2003:1a59:50a9:acdc::36
      </li><br>

    <li><a name="">authentication</a><br>
      Used to enable basic authentication for incoming requests<br>
      Note that user, pass and authentication attribute must be set to activate
      basic authentication<br>
      Possible values: 0,1<br>
      Default: 0</li><br>

    <li><a name="">autocreate</a><br>
      Used to overwrite global autocreate setting<br>
      Possible values: 0,1<br>
      Default: not set</li><br>
      
    <li><a name="">autosave</a><br>
      Used to overwrite global autosave setting<br>
      Possible values: 0,1<br>
      Default: not set</li><br>
      
    <li><a name="">combineDevices</a><br>
      Used to gather all ESP devices of a single ESP into 1 FHEM device even if
      different ESP devices names are used.<br>
      Possible values: 0, 1, IPv64 address, IPv64/netmask, ESPname or a comma
      separated list consisting of these values.<br>
      Netmasks can be written as bitmask or dotted decimal. Domain names for dns
      lookups are not supported.<br>
      Default: 0 (disabled for all ESPs)<br>
      Eg. 1 (globally enabled)<br>
      Eg. ESP01,ESP02<br>
      Eg. 10.68.30.1,10.69.0.0/16,ESP01,2002:1a59:50a9::/48</li><br>

    <li><a name="">deniedIPs</a><br>
      Used to define IPs or IP ranges of ESPs which are denied to commit data.
      <br>
      Syntax see <a href="#ESPEasyallowedIPs">allowedIPs</a>.<br>
      This attribute will overwrite any IP or range defined by
      <a href="#ESPEasyallowedIPs">allowedIPs</a>.<br>
      Default: none (no IPs are denied)</li><br>

    <li><a name="">disable</a><br>
      Used to disable device<br>
      Possible values: 0,1<br>
      Default: 0 (eanble)</li><br>
      
    <li><a name="">httpReqTimeout</a><br>
      Specifies seconds to wait for a http answer from ESP8266 device<br>
      Possible values: 4..60<br>
      Default: 10 seconds</li><br>
      
    <li><a name="ESPEasyuniqIDs">uniqIDs</a><br>
      <b>This attribute is deprecated and will be removed soon.</b><br>
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
      
    <li><a name="">pinMap</a><br>
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

    <li><a name="">clearReadings</a><br>
      Delete all readings that are auto created by received sensor values
      since last FHEM restart<br>
      required values: <code>&lt;none&gt;</code></li><br>
      
    <li><a name="">help</a><br>
      Shows set command usage<br>
      required values: <code>a valid set command</code></li><br>
      
    <li><a name="">statusRequest</a><br>
      Trigger a statusRequest for configured GPIOs (see attribut pollGPIOs)
      and do a presence check<br>
      required values: <code>&lt;none&gt;</code></li><br>
      
    <li><a name="">Event</a><br>
      Create an event. Such events can be used in ESP rules.<br>
      required value: <code>&lt;string&gt;</code></li><br>
      
    <li><a name="">GPIO</a><br>
      Direct control of output pins (on/off)<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt;</code><br>
      see <a target="_new"
      href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li><a name="">PWM</a><br>
      Direct PWM control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a>
      for details</li><br>
      
    <li><a name="">PWMFADE</a><br>
      PWMFADE control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;target&gt; &lt;duration&gt;
      </code><br>
      pin: 0-3 (0=r,1=g,2=b,3=w), target: 0-1023, duration: 1-30 seconds.
      </li><br>

    <li><a name="">Pulse</a><br>
      Direct pulse control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt; &lt;duration&gt;</code>
      <br>
      see <a target="_new"
      href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li><a name="">LongPulse</a><br>
      Direct pulse control of output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt; &lt;duration&gt;</code>
      <br>
      see <a target="_new"
      href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>

    <li><a name="">Servo</a><br>
      Direct control of servo motors<br>
      required arguments: <code>&lt;servoNo&gt; &lt;pin&gt; &lt;position&gt;
      </code><br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for
      details</li><br>
      
    <li><a name="">lcd</a><br>
      Write text messages to LCD screen<br>
      required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
      see 
      <a target="_new" 
      href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay
      </a> for details</li><br>
      
    <li><a name="">lcdcmd</a><br>
      Control LCD screen<br>
      required arguments: <code>&lt;on|off|clear&gt;</code><br>
      see 
      <a target="_new" 
      href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay
      </a> for details</li><br>
      
    <li><a name="">mcpgpio</a><br>
      Control MCP23017 output pins<br>
      required arguments: <code>&lt;pin&gt; &lt;0,1&gt;</code><br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/MCP23017">ESPEasy:MCP23017
      </a>for details</li><br>
      
    <li><a name="">oled</a><br>
      Write text messages to OLED screen<br>
      required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
      see
      <a target="_new" 
      href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay
      </a> for details.</li><br>
      
    <li><a name="">oledcmd</a><br>
      Control OLED screen<br>
      required arguments: <code>&lt;on|off|clear&gt;</code><br>
      see 
      <a target="_new" 
      href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay
      </a> for details.</li><br>
      
    <li><a name="">pcapwm</a><br>
      Control PCA9685 pwm pins<br>
      required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/PCA9685">ESPEasy:PCA9685</a>
      for details</li><br>
      
    <li><a name="">PCFLongPulse</a><br>
      Long pulse control on PCF8574 output pins<br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      for details</li><br>

    <li><a name="">PCFPulse</a><br>
      Pulse control on PCF8574 output pins<br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      for details</li><br>
      
    <li><a name="">pcfgpio</a><br>
      Control PCF8574 output pins<br>
      see <a target="_new" 
      href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
      </li><br>
      
    <li><a name="">raw</a><br>
      Can be used for own ESP plugins that are not considered at the moment.<br>
      Usage: raw &lt;cmd&gt; &lt;param1&gt; &lt;param2&gt; &lt;...&gt;<br>
      eg: raw myCommand 3 1 2</li><br>
      
    <li><a name="">status</a><br>
      Request esp device status (eg. gpio)<br>
      required values: <code>&lt;device&gt; &lt;pin&gt;</code><br>
      eg: <code>gpio 13</code></li><br>
  </ul>

  <br><a name="ESPEasyattr"></a>
  <b>Attributes</b> (logical device)<br><br>

  <ul>
    <li><a name="">adjustValue</a><br>
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
      
    <li><a name="">disable</a><br>
      Used to disable device<br>
      Possible values: 0,1<br>
      Default: 0</li><br>

    <li><a name="ESPEasyInterval">Interval</a><br>
      Used to set polling interval for presence check and GPIOs polling in
      seconds. 0 will disable this feature.<br>
      Possible values: secs &gt; 10.<br>
      Default: 300</li><br>
      
    <li><a name="">presenceCheck</a><br>
      Used to enable/disable presence check for ESPs<br>
      Presence check determines the presence of a device by readings age. If any
      reading of a device is newer than <a href="#ESPEasyInterval">interval</a>
      seconds than it is marked as being present. This kind of check works for
      ESP devices in deep sleep too but require at least 1 reading that is
      updated regularly.<br>
      If the FHEM device contains values from more than 1 ESP (see Attribute
      <a href="#ESPEasyuniqIDs">uniqIDs</a>) than there is an additional
      presence state: "partial absent (ip)" besides present and absent.<br>
      Possible values: 0,1<br>
      Default: 1 (enabled)</li><br>
      
    <li><a name="">readingSwitchText</a><br>
      Use on,off instead of 1,0 for readings if ESP device is a switch.<br>
      Possible values: 0,1<br>
      Default: 1 (enabled)</li><br>

    <li><a name="">setState</a><br>
      Summarize received values in state reading.<br>
      Set to 0 to disable this feature. A positive number determines the number
      of characters used for reading names. Only readings with an age less than
      <a href="#ESPEasyInterval">interval</a> will be considered.<br>
      Reading state will be updated only if a value has been changed to reduce
      events.<br>
      Possible values: integer &gt;=0<br>
      Default: 3 (enabled with 3 characters abbreviation)</li><br>

      <b>The following 4 attributes should only be use in cases where ESPEasy
      software do not send data on status changes and no rule/dummy can be used
      to do that. Useful for commands like PWM, STATUS, ...</b>
      <br><br>
    
    <li><a name="">parseCmdResponse</a><br>
      Used to parse response of commands like GPIO, PWM, STATUS, ...<br>
      Specify a module command or comma separated list of commands as argument.
      Commands are case insensitive.<br>
      Only necessary if ESPEasy software plugins do not send their data
      independently. Useful for commands line STATUS, PWM, ...<br>
      Possible values: &lt;set cmd&gt;[,&lt;set cmd&gt;][,...]<br>
      Default: status<br>
      Eg. <code>attr ESPxx parseCmdResponse status,pwm</code></li><br>

    <li><a name="ESPEasypollGPIOs">pollGPIOs</a><br>
      Used to enable polling for GPIOs status. This polling will do same as
      command 'set ESPxx status &lt;device&gt; &lt;pin&gt;'<br>
      Possible values: GPIO number or comma separated GPIO number list<br>
      Default: none<br>
      Eg. <code>attr ESPxx pollGPIOs 13,D7,D2</code></li><br>
      
      <b>The following 2 attributes control naming of readings that are
      generated by help of parseCmdResponse and pollGPIOs (see above)</b>
      <br><br>

    <li><a name="">readingPrefixGPIO</a><br>
      Specifies a prefix for readings based on GPIO numbers. For example:
      "set ESPxx pwm 13 512" will switch GPIO13 into pwm mode and set pwm to
      512. If attribute readingPrefixGPIO is set to PIN and attribut
      parseCmdResponse contains pwm command then the reading name
      will be PIN13.<br>
      Possible Values: <code>string</code><br>
      Default: GPIO</li><br>
      
    <li><a name="">readingSuffixGPIOState</a><br>
      Specifies a suffix for the state-reading of GPIOs (see Attribute
      <a href="#ESPEasypollGPIOs">pollGPIOs</a>)<br>
      Possible Values: <code>string</code><br>
      Default: no suffix<br>
      Eg. attr ESPxx readingSuffixGPIOState _state</li><br>
   
  </ul>
</ul>

=end html
=cut
