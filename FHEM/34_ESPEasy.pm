# $Id$
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
#
#   Credit goes to:
#   - ESPEasy Project
#
################################################################################

package main;

use strict;
use warnings;
use Data::Dumper;
use HttpUtils;

my $ESPEasy_version = "0.1.3";
my $ESPEasy_desc    = 'Control ESP8266/ESPEasy';

# ------------------------------------------------------------------------------
# "setCmds" => "number of parameters"
# ------------------------------------------------------------------------------
my %ESPEasy_setCmds = (
  "gpio"           => "2",
  "pwm"            => "2",
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
  "statusrequest"  => "0", 
  "presencecheck"  => "0",
  "clearreadings"  => "0",
  "help"           => "1"
);

# ------------------------------------------------------------------------------
# "setCmds" => "syntax", pin mapping will parse for <pin> position
# ------------------------------------------------------------------------------
my %ESPEasy_setCmdsUsage = (
  "gpio"           => "gpio <pin> <0|1|off|on>",
  "pwm"            => "pwm <pin> <level>",
  "pulse"          => "pulse <pin> <0|1|off|on> <duration>",
  "longpulse"      => "longpulse <pin> <0|1|off|on> <duration>",
  "servo"          => "Servo <servoNo> <pin> <position>",
  "lcd"            => "lcd <row> <col> <text>",
  "lcdcmd"         => "lcdcmd <on|off|clear>",
  "mcpgpio"        => "mcpgpio <pin> <0|1|off|on>",
  "oled"           => "oled <row> <col> <text>",
  "oledcmd"        => "pcapwm <on|off|clear>",
  "pcapwm"         => "pcapwm <pin> <Level>",
  "pcfgpio"        => "pcfgpio <pin> <0|1|off|on>",
  "pcfpulse"       => "pcfpulse <pin> <0|1|off|on> <duration>",    #missing docu
  "pcflongPulse"   => "pcflongPulse <pin> <0|1|off|on> <duration>",#missing docu
  "status"         => "status <device> <pin>",

  "statusrequest"  => "statusRequest",
  "presencecheck"  => "presenceCheck",
  "clearreadings"  => "clearReadings",
  "help"           => "help <".join("|", sort keys %ESPEasy_setCmds).">"
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
sub ESPEasy_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}        = "ESPEasy_Define";
  $hash->{GetFn}        = "ESPEasy_Get";
  $hash->{SetFn}        = "ESPEasy_Set";
  $hash->{AttrFn}       = "ESPEasy_Attr";
  $hash->{UndefFn}      = "ESPEasy_Undef";
  $hash->{ShutdownFn}	  =	"ESPEasy_Shutdown";
  $hash->{DeleteFn}	    = "ESPEasy_Delete";

  $hash->{AttrList}     = "do_not_notify:0,1 ".
                          "disable:1,0 ".
                          "Interval ".
                          "pollGPIOs ".
                          "debug ".
                          $readingFnAttributes;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Define($$)  # only called when defined, not on reload.
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  my $usg = "Use 'define <name> ESPEasy <ip|fqdn> [PORT]";

  return "Wrong syntax: $usg" if(int(@a) < 2);

  my $name = $a[0];
  my $type = $a[1];
  my $host = $a[2];

  if (ESPEasy_isIPv4($host) || ESPEasy_isFqdn($host)) {
    $hash->{HOST} = $host
  } else {
    return "ERROR: invalid IPv4 address or fqdn: '$host'"
  }

  $hash->{PORT} = !$a[3] ? 80 : $a[3];
  $hash->{VERSION} = $ESPEasy_version;
  $hash->{helper}{urlcmd} = "/control?cmd=";
	$hash->{helper}{noPm_JSON} = 1 if (ESPEasy_isPmInstalled($hash,"JSON"));

	readingsSingleUpdate($hash, 'state', 'opened',1);
  Log3 $hash->{NAME}, 2, "ESPEasy: opened device $name -> host:$hash->{HOST}:".
                         "$hash->{PORT}";

  InternalTimer(gettimeofday()+.1, "ESPEasy_deleteReadings", $hash);
  InternalTimer(gettimeofday()+10, "ESPEasy_statusRequest", $hash);
  return undef;
}


# ------------------------------------------------------------------------------
#UndefFn: called while deleting device (delete-command) or while rereadcfg
sub ESPEasy_Undef($$)
{
  my ($hash, $arg) = @_;
  HttpUtils_Close($hash);
  return undef;
}


# ------------------------------------------------------------------------------
#ShutdownFn: called before fhem's shutdown command
sub ESPEasy_Shutdown($)
{
	my ($hash) = @_;
  HttpUtils_Close($hash);
  Log3 $hash->{NAME}, 2, "$hash->{TYPE}: device $hash->{NAME} shutdown requested";
	return undef;
}


# ------------------------------------------------------------------------------
#DeleteFn: called while deleting device (delete-command) but after UndefFn
sub ESPEasy_Delete($$)
{
  my ($hash, $arg) = @_;
  Log3 $hash->{NAME}, 2, "$hash->{TYPE}: $hash->{NAME} deleted";
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_Attr(@)
{
  my ($cmd,$name,$aName,$aVal) = @_;
  my $hash = $defs{$name};
  my $type = $hash->{NAME};
  my $ret = undef;

  # InternalTimer will be called from notifyFn if disabled = 0
  if ($aName eq "disable") {
    $ret="0,1" if ($cmd eq "set" && not $aVal =~ /(0|1)/);
    if ($cmd eq "set" && $aVal == 1) {
      Log3 $name, 3,"$type: $name is disabled";
      ESPEasy_deleteReadings($hash);
      ESPEasy_resetTimer($hash,"stop");
      readingsSingleUpdate($hash, "state", "disabled",1);
    }
    elsif ($cmd eq "del" || $aVal == 0) {
      InternalTimer(gettimeofday()+2, "ESPEasy_resetTimer", $hash);
      readingsSingleUpdate($hash, 'state', 'opened',1);
    }

  } elsif ($aName eq "pollGPIOs") {
    if ($cmd eq "set") {
      if ($aVal =~ /^[0-9]+(,[0-9]+)*$/) {
        #InternalTimer(gettimeofday()+1, "ESPEasy_resetTimer", $hash); # better use notifyFn?
      }
      else {
        $ret ="GPIO_No[,GPIO_No][...]"
      }
    }
    else { #cmd eq del
      #ESPEasy_resetTimer($hash);
    }

  } elsif ($aName eq "Interval") {
    if ($cmd eq "set" && $aVal < 10) {
      $ret =">10";
    }
  }

  if (defined $ret) {
    Log3 $name, 2, "$type: attr $name $aName $aVal != $ret";
    return "$aName must be: $ret";
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
    $ret .= "pin mapping:\n";
    foreach (sort keys %ESPEasy_pinMap) {
      $ret .= $_." " x (5-length $_ ) ."=> $ESPEasy_pinMap{$_}\n";
    }
    return $ret;
  }

  elsif (exists($hash->{READINGS}{$reading})) {
    if (defined($hash->{READINGS}{$reading})) {
      return $hash->{READINGS}{$reading}{VAL};
    }
    else {
      return "no such reading: $reading";
    }
  }

  else {
    $ret = "unknown argument $reading, choose one of";
    foreach my $reading (sort keys %{$hash->{READINGS}}) {
      $ret .= " $reading:noArg";
    }
    
    return $ret . " pinMap:noArg";
  }
}


# ------------------------------------------------------------------------------
sub ESPEasy_Set($$@)
{
  my ($hash, $name, $cmd, @params) = @_;
  my ($type,$self) = ($hash->{TYPE},ESPEasy_whoami());
  $cmd = lc($cmd) if $cmd;

  Log3 $hash->{NAME}, 5, "$name: $self() got: name:$name, cmd:$cmd, ".
                         "params:".join(" ",@params) if ($cmd ne "?" && AttrVal($name,"debug","") ne "");

  return if (IsDisabled $name);

  # are there all required argumets?
  if($ESPEasy_setCmds{$cmd} && scalar @params < $ESPEasy_setCmds{$cmd}) {
    Log3 $name, 1, "$type: Missing argument: 'set $name $cmd ".join(" ",@params)."'";
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
    Log3 $name, 4, "$type: pin mapping ". uc $params[$pp-1] .
                   " => $ESPEasy_pinMap{uc $params[$pp-1]}";
    $params[$pp-1] = $ESPEasy_pinMap{uc $params[$pp-1]};
  }

  # onOff mapping (on/off -> 1/0)
  $pp = ESPEasy_paramPos($cmd,'<0|1|off|on>');
  if ($pp && not($params[$pp-1] =~ /^0|1$/)) {
    my $state = ($params[$pp-1] eq "off") ? 0 : 1;
    Log3 $name, 4, "$type: onOff mapping ". $params[$pp-1]." => $state";
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

  if ($cmd eq "presencecheck") {
    ESPEasy_checkPresence($hash);
    return undef;
  }

  if ($cmd eq "clearreadings") {
    ESPEasy_deleteReadings($hash);
    return undef;
  }

  ESPEasy_httpRequest($hash, $cmd, @params);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_statusRequest($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $type = $hash->{TYPE};

  my $a = AttrVal($name,"pollGPIOs","");
  my @gpios = split(",",$a);

  Log3 $name, 3, ($a eq "") ? "$type: set $name statusRequest (presence only)" 
                            : "$type: set $name statusRequest";

  foreach my $gpio (@gpios) {
    ESPEasy_httpRequest($hash, "status", "gpio,".$gpio);
  }

  ESPEasy_checkPresence($hash) if $a eq "";
  ESPEasy_resetTimer($hash);
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_httpRequest($$@)
{
  my ($hash, $cmd, @params) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});
  my $plist = join(",",@params);
  Log3 $name, 4, "$type: set $name $cmd,$plist";

  $cmd = $cmd."," if $params[0];
  my $url = "http://".$hash->{HOST}.":".$hash->{PORT}.$hash->{helper}{urlcmd}.$cmd.$plist;

  Log3 $name, 5, "$type: url => $url";

  my $httpParams = {
    url         => $url,
    timeout     => 10,
    keepalive   => 0,
    httpversion => "1.0",
    hideurl     => 0,
    method      => "GET",
    hash        => $hash,
    cmd         => $cmd,     # passthrought to parseFn;
    plist       => $plist,   # passthrought to parseFn;
    callback    =>  \&ESPEasy_httpRequestParse
  };
  HttpUtils_NonblockingGet($httpParams);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_httpRequestParse($$$)
{
  my ($param, $err, $data) = @_;
  my $hash = $param->{hash};
  my ($name,$type,$self) = ($hash->{NAME},$hash->{TYPE},ESPEasy_whoami());

  if ($err ne "" && ReadingsVal($name,"presence","???") ne "absent") {
    Log3 $name, 4, "$type: $name error: $err";
    Log3 $name, 4, "$type: $name presence: absent";
    ESPEasy_deleteReadings($hash);
    readingsSingleUpdate($hash, 'presence', 'absent',1);
  }

  elsif ($data ne "") 
  { 
    if (ReadingsVal($name,"presence","???") ne "present") { 
      Log3 $name, 4, "$type: $name presence: present";
      readingsSingleUpdate($hash, 'presence', 'present',1);
    }

    # no errors occurred
    Log3 $name, 5, "$type: $name $self() data: \n $data" if AttrVal($name,"debug","") ne "";
    if (!defined $hash->{helper}{noPm_JSON}) {
      if ($data =~ /^{/) {
        use JSON;
        my %res = %{decode_json($data)};
        Log3 $name, 4, "$type: $name $param->{cmd}$param->{plist} => mode:$res{mode} state:$res{state}";

        $res{state} = ($res{state} == 1) ? "on" : "off" if $res{mode} =~ /^output|input$/;
        readingsBeginUpdate($hash);
        readingsBulkUpdate($hash, "GPIO".$res{pin}."_mode", $res{mode});
        readingsBulkUpdate($hash, "GPIO".$res{pin}."_state", $res{state});
        readingsBulkUpdate($hash, "lastResult", $res{log}) if $res{log} ne "";
        readingsEndUpdate($hash, 1);

        Log3 $name, 4, "$type: $name $param->{cmd}$param->{plist} => $res{log}" if $res{log} ne "";
      } #if data =~/^{//

      else { # no json returned
        Log3 $name, 2, "$type: $name $param->{cmd}$param->{plist} => $data";
        if ($param->{plist} =~/^gpio,(\d+)/) {
          ESPEasy_deleteReadings($hash,"GPIO".$1."_mode");
          ESPEasy_deleteReadings($hash,"GPIO".$1."_state");
        }
      }
    }

    else { # no json installed
      Log3 $name, 2, "type: perl module JSON not installed.";
    }
  } # ($data ne "") 
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_checkPresence($)
{
  my ($hash) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});
  my $url = "http://$hash->{HOST}:$hash->{PORT}/";
  Log3 $name, 5, "$type: presence check url: $url";
 
  my $httpParams = {
    url         => $url,
    timeout     => 5,
    keepalive   => 0,
    httpversion => "1.0",
    hideurl     => 0,
    method      => "GET",
    hash        => $hash,
    callback    =>  \&ESPEasy_checkPresenceParse
  };
  HttpUtils_NonblockingGet($httpParams);

  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_checkPresenceParse($$$)
{
  my ($param, $err, $data) = @_;
  my $hash = $param->{hash};
  my ($name,$type,$self) = ($hash->{NAME},$hash->{TYPE},ESPEasy_whoami());
  readingsBeginUpdate($hash);

  if ($err ne "" && ReadingsVal($name,"presence","???") ne "absent") {
    Log3 $name, 4, "$type: $name error: $err";
    Log3 $name, 4, "$type: $name presence: absent";
    ESPEasy_deleteReadings($hash);
    readingsSingleUpdate($hash, 'presence', 'absent',1);
  }

  elsif ($data ne "" && ReadingsVal($name,"presence","???") ne "present") { 
    Log3 $name, 4, "$type: $name presence: present";
    readingsBulkUpdate($hash, 'presence', 'present',1);
  }

  readingsEndUpdate($hash,1);
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_resetTimer($;$)
{
  my ($hash,$sig) = @_;
  my $name = $hash->{NAME};
  $sig = "" if !$sig;

  RemoveInternalTimer($hash, "ESPEasy_statusRequest") if $init_done == 1;
  
#  return undef if (AttrVal($name,"pollGPIOs","") eq "" || $sig eq "stop");
  return undef if $sig eq "stop";
    
  unless(IsDisabled($name)) {
    InternalTimer(gettimeofday()+AttrVal($name,"Interval",300), "ESPEasy_statusRequest", $hash);
  }
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_deleteReadings($;$)
{
  my ($hash,$reading) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});

  if ($reading) {
    if (defined $hash->{READINGS}{$reading}) {
      delete $hash->{READINGS}{$reading};
      Log3 $name, 3, "$type: $name reading $reading wiped out";
    }
    return undef;
  } 

  else {
    my @dr;
    my @r = keys $hash->{READINGS};
    foreach my $r (@r) {
      if ($r =~ m/^GPIO/) {
        delete $hash->{READINGS}{$r};
        push(@dr,$r);
      }
    }
    Log3 $name, 3, "$type: $name readings [".join(",",@dr)."] wiped out" if scalar @dr > 1;
  }

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
sub ESPEasy_isPmInstalled($$)
{
  my ($hash,$pm) = @_;
  my ($name,$type) = ($hash->{NAME},$hash->{TYPE});
  if (not eval "use $pm;1")
  {
    Log3 $name, 1, "$type: perl modul missing: $pm. Install it, please.";
    $hash->{MISSING_MODULES} .= "$pm ";
    return "failed: $pm";
  }
  return undef;
}


# ------------------------------------------------------------------------------
sub ESPEasy_isIPv4($) {return if(!defined $_[0]); return 1 if($_[0] =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/)}


# ------------------------------------------------------------------------------
sub ESPEasy_isFqdn($) {return if(!defined $_[0]); return 1 if($_[0] =~ /^(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)$/)}


# ------------------------------------------------------------------------------
sub ESPEasy_whoami()  {return (split('::',(caller(1))[3]))[1] || '';}


=pod
=item device
=begin html

<a name="ESPEasy"></a>
<h3>ESPEasy</h3>
<ul>
  <p>
    Provides control to ESP8266/ESPEasy
  </p>
  <b>Notes</b>
  <ul>
    <li>Requirements: perl module <b>JSON</b> lately.
      There is reduced functionality if it is not installed, but the module
      will work with basic functions. Use "cpan install JSON" or operating
      system's package manager to install JSON Modul. Depending on your os
      the required package is named: libjson-perl or perl-JSON.
      </li><br>
  </ul>

  <br>

  <a name="ESPEasydefine"></a>
  <b>Define</b>
  <ul>

  <code>define &lt;name&gt; ESPEasy &lt;ip_address|fqdn&gt; [&lt;port&gt;]
  </code>
  <br>

  <p><u>Mandatory:</u></p>
  <ul>
  <code>&lt;name&gt;</code>
  <ul>Specifies a device name of your choise.<br>
  eg. <code>ESPxx</code>
  </ul><br>
  <code>&lt;ip_address|fqdn&gt;</code>
  <ul>Specifies device IP address or hostname.<br>
    eg. <code>172.16.4.100</code><br>
    eg. <code>espxx.your.domain.net</code>
  </ul>
  </ul>

  <p><u>Optional</u></p>
  <ul>
  <code>&lt;port&gt;</code>
  <ul>Specifies your http port to be used. Default: 80<br>
  eg.<code> 88</code><br>
  </ul>

  </ul>

    <p><u>Define Examples:</u></p>
    <ul>
      <li><code>define ESPxx ESPEasy 172.16.4.100</code></li>
      <li><code>define ESPxx ESPEasy 172.16.4.100 81</code></li>
    </ul>
  </ul>
<br>

  <a name="ESPEasyget"></a>
  <b>Get </b>
  <ul>
    <li>&lt;reading&gt;<br>
      returns the value of the specified reading<br>
      </li><br>

    <li>pinMap<br>
      returns possible alternative pin names that can be used in commands<br>
      </li><br>
  </ul>

<br>

  <a name="ESPEasyset"></a>
  <b>Set </b>
<br>
  <ul>
Notes:<br>
- Commands are case insensitive.<br>
- Users of Wemos D1 mini or NodeMCU can use Arduino pin names instead of GPIO 
no: D1 =&gt; GPIO5, D2 =&gt; GPIO4, ...,TX =&gt; GPIO1 (see: get pinMap)
- low/high state can be written as 0/1 or on/off
<br><br>

<li>Event<br>
Create an event 
<br>
required value: <code>&lt;string&gt;</code><br>
</li>
<br>

<li>GPIO<br>
Direct control of output pins (on/off)
<br>
required arguments: <code>&lt;pin&gt; &lt;0|1&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for details
<br>
</li>
<br>

<li>PWM<br>
Direct PWM control of output pins 
<br>
required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for details
<br>
</li>
<br>

<li>Pulse<br>
Direct pulse control of output pins
<br>
required arguments: <code>&lt;pin&gt; &lt;0|1&gt; &lt;duration&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for details
<br>
</li>
<br>

<li>LongPulse<br>
Direct pulse control of output pins
<br>
required arguments: <code>&lt;pin&gt; &lt;0|1&gt; &lt;duration&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for details
<br>
</li>
<br>

<li>Servo<br>
Direct control of servo motors
<br>
required arguments: <code>&lt;servoNo&gt; &lt;pin&gt; &lt;position&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/GPIO">ESPEasy:GPIO</a> for details
<br>
</li>
<br>

<li>lcd<br>
Write text messages to LCD screen
<br>
required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay</a> 
for details
<br>
</li>
<br>

<li>lcdcmd<br>
Control LCD screen
<br>
required arguments: <code>&lt;on|off|clear&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/LCDDisplay">ESPEasy:LCDDisplay</a> 
for details
<br>
</li>
<br>

<li>mcpgpio<br>
Control MCP23017 output pins
<br>
required arguments: <code>&lt;pin&gt; &lt;0|1&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/MCP23017">ESPEasy:MCP23017</a> 
for details
<br>
</li>
<br>

<li>oled<br>
Write text messages to OLED screen
<br>
required arguments: <code>&lt;row&gt; &lt;col&gt; &lt;text&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay</a>
<br>
</li>
<br>

<li>oledcmd<br>
Control OLED screen
<br>
required arguments: <code>&lt;on|off|clear&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/OLEDDisplay">ESPEasy:OLEDDisplay</a>
<br>
</li>
<br>

<li>pcapwm<br>
Control PCA9685 pwm pins 
<br>
required arguments: <code>&lt;pin&gt; &lt;level&gt;</code><br>
see <a href="http://www.esp8266.nu/index.php/PCA9685">ESPEasy:PCA9685</a>
<br>
</li>
<br>

<li>PCFLongPulse<br>
Long pulse control on PCF8574 output pins
<br>
see <a href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a> for 
details
<br>
</li>
<br>

<li>PCFPulse<br>
Pulse control on PCF8574 output pins 
<br>
see <a href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a> for 
details
<br>
</li>
<br>

<li>pcfgpio<br>
Control PCF8574 output pins
<br>
see <a href="http://www.esp8266.nu/index.php/PCF8574">ESPEasy:PCF8574</a>
<br>
</li>
<br>

<li>status<br>
Request esp device status (eg. gpio)
<br>
required values: <code>&lt;device&gt; &lt;pin&gt;</code><br>
eg: <code>&lt;gpio&gt; &lt;13&gt;</code><br>
</li>
<br>

<li>help<br>
Shows set command usage
<br>
required values: <code>
Event|GPIO|PCFLongPulse|PCFPulse|PWM|Publish|Pulse|Servo|Status|lcd|lcdcmd|
mcpgpio|oled|oledcmd|pcapwm|pcfgpio|status|statusRequest|presenceCheck|
clearReadings|help
</code><br>
</li>
<br>

<li>statusRequest<br>
Trigger a statusRequest for configured GPIOs (see attribut pollGPIOs) and a 
presenceCheck
<br>
required values: <code>&lt;none&gt;</code><br>
</li>
<br>

<li>presenceCheck<br>
Trigger a presenceCheck
<br>
required values: <code>&lt;none&gt;</code><br>
</li>
<br>

<li>clearReadings<br>
Delete all GPIO.* readings
<br>
required values: <code>&lt;none&gt;</code><br>
</li>
<br>

  </ul>

<br>

 <a name="ESPEasyattr"></a>
  <b>Attributes</b>
  <ul>
    <li>disable<br>
      Used to disable device<br>
      Possible values: 0,1<br>
      </li><br>
    <li>pollGPIOs<br>
      Used to enable polling of GPIOs status<br>
      Possible values: comma separated GPIO number list<br>
      Eg. <code>13,15</code>
      </li><br>
    <li>Interval<br>
      Used to set polling Interval of GPIOs in seconds<br>
      Possible values: secs > 10<br>
      Default: 300
      Eg. <code>300</code>
      </li><br>
    <li>debug<br>
      Enable a more verbose logging.<br>
      </li><br>
  </ul>
</ul>

=end html

=cut

1;

