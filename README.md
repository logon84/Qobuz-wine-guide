# Qobuz-wine-guide
A guide to make Qobuz run bitperfect under linux

Guide to install Qobuz app on linux, trying to achieve the best possible latency/quality playback.

#INSTALLING WINE-STAGING:
```
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
sudo apt update
sudo apt install wine-staging wine-staging-amd64 wine-staging-i386 inotify-tools
WINEPREFIX=~/.wine-staging /opt/wine-staging/bin/winecfg
```
At this point, set:

-Windows 7 as OS  
-Enable VAAPI as backend

-Idk if it is important, but I downloaded this file https://dll.website/download/msvproc_dll_417e414c57cd55fdee5f0bdcf331c967.zip and copied the dll to ~/.wine-staging/drive_c/windows/syswow64

#CHANGE WINE AUDIO TO ALSA:
```
WINEPREFIX=~/.wine-staging WINE=/opt/wine-staging/bin/wine winetricks
```
-->default wine prefix->change settings->sound=alsa

#INSTALL QOBUZ:  
First, run installer prequisites.sh

Then:
```
wget https://desktop.qobuz.com/releases/win32/x64/windows7_8_10/8.1.0-b019/Qobuz_Installer.exe
WINEPREFIX=~/.wine-staging /opt/wine-staging/bin/wine Qobuz_Installer.exe
```
Now Qobuz should open asking for login.
After logging in, close Qobuz.  

#PIPEWIRE CONFIG:  
Now check if you have a file named pipewire.conf in ~/.config/pipewire/. If you don't, copy the file from /usr/share/pipewire/pipewire.conf to that folder.
Open the file and edit the line containing: "#default.clock.allowed-rates"

to

"default.clock.allowed-rates = [ 44100 48000 96000 176400 192000]"
Depending of your computer power, you probably need to play with quantum settings. In my case, this config is perfect for my old computer:
```
default.clock.quantum       = 16
default.clock.min-quantum   = 16
default.clock.max-quantum   = 256
```

I also did some changes in the file ~/.config/wireplumber/main.lua.d/50-alsa-config:
```
      ["resample.disable"]       = true,
      ["audio.channels"]         = 2,
      ["audio.format"]           = "S24-32LE",
      ["audio.allowed-rates"]    = "44100 48000 96000 176400 192000",
      ["audio.position"]         = "FL,FR",
      ["api.alsa.period-size"]   = 1024,
      ["api.alsa.headroom"]      = 4096,
      ["session.suspend-timeout-seconds"] = 0,  -- 0 disables suspend
```
Restart the pipewire daemon with: 
```
systemctl --user restart wireplumber pipewire pipewire-pulse
```
Open pavucontrol and change playback device to the "pro" profile.

Copy steam-wire.lua to folder "$HOME/.config/wireplumber/scripts/

#ENJOY  
From now on, open Qobuz using the qobuz_launcher script (hold shift key or run script with -exclusive flag to use exclusive mode). 
If Qobuz refuses to connect to your desired output device, go to Qobuz settings and turn off "exclusive mode" (in my computer at least, the output device is just called "Out:default"). After that, remember to
select Max playing quality clicking on the quality section, between volume control and pulseaudio Label.
To avoid problems you should set 2 channel audio (stereo) in 50-alsa-config.lua and in winecfg audio tab (env WINEPREFIX="$HOME/.wine-staging" /opt/wine-staging/bin/winecfg).

[![Donate](https://www.paypalobjects.com/es_ES/ES/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ER2LTNM5LZDTY)  
BTC address: 12cQuFn7yMSfDB1uKPGKLMQ7XSj1XF2sVA

