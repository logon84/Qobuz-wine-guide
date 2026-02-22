#!/bin/bash
# Qobuz launcher script v 1.8 @Logon84 2026

#To use Qobuz with wine and ALSA sound, disable "Exclusive mode" inside qobuz app.
#If you want to run Qobuz with exclusive mode under linux, either run this script with "-exclusive" flag or run the script while holding shift key.
#To avoid problems you should set 2 channel audio (stereo) in 50-alsa-config.lua and in winecfg audio tab (env WINEPREFIX="$HOME/.wine-staging" /opt/wine-staging/bin/winecfg)

#Edit this 2 vars if needed
wine_prefix="$HOME/.wine-staging"
wine_binary="/opt/wine-staging/bin/wine"

#aux
wine_username=$(env $(eval "WINEPREFIX=$wine_prefix") $wine_binary cmd /c set | grep "^USERNAME=" | awk -F '=' '{print ($2)}'  | tr -d '\r')
exit_text='AppPolicyGetProcessTerminationMethod FFFFFFFFFFFFFFFA'

#check launching mode
keyboard_xinput=$(xinput --list --long | grep -Fwm1 XIKeyClass | egrep -oE '[0-9]*')
shift_pressed=$(xinput query-state $keyboard_xinput | grep down | grep -E "50|62")
if [ "$1" = "-exclusive" ] || [ ! -z "$shift_pressed" ]; then
    if ! command -v jq >/dev/null 2>&1
    then
        echo "Jq is needed to run Qobuz in exclusive mode"
        exit 1
    fi

    #Notify
    echo -e "\n\n\n\nLaunching Qobuz in HW Exclusive Mode\n\n\n\n"
    gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.Notify \
             Qobuz-wine 0 gtk-dialog-info \
             "Qobuz-wine" "Launching Qobuz in HW Exclusive Mode" [] \
            "{'transient': <true>}" 5000 > /dev/null 2>&1

    #get device to play to and make it exclusive
    speakers_sink_name=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a '*' | awk '{print ($4)}')
    speakers_alsa_id=$(pw-dump | jq '.[] | select(.info.props."node.name"=="'"${speakers_sink_name}"'") | .info.props."device.id"')
    speakers_audio_n=$(pw-dump | jq '.[] | select(.info.props."object.id"=='"${speakers_alsa_id}"') | .info.props."api.dbus.ReserveDevice1"' | tr -d "\"")
    pw-reserve -r -n $speakers_audio_n &
    pw_res_pid=$!

    #launch Qobuz
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $(dirname $wine_binary)/winecfg -v win7
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $wine_binary C:\\users\\$wine_username\\AppData\\Local\\Qobuz\\Qobuz.exe > $wine_prefix/drive_c/users/$wine_username/AppData/Roaming/Qobuz/wine.log 2>&1

    #Wait for closing qobuz
    ( tail -f -n0 $wine_prefix/drive_c/users/$wine_username/AppData/Roaming/Qobuz/wine.log & ) | grep -Eq "$exit_text"
    echo -e "\n\n\n\nClosing....\n\n\n\n"
    
    #destroy device exclusive mode & restore default pipewire device
    kill -15 $pw_res_pid 2> /dev/null
    wait $pw_res_pid 2> /dev/null
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 2
    past_default_new_id=$(wpctl status -n | grep -a $speakers_sink_name | grep vol | awk '{print ($3+0)}')
    wpctl set-default $past_default_new_id

else
    #Notify
    echo -e "\n\n\n\nLaunching Qobuz in HW Shared (non-Exclusive) Mode\n\n\n\n"
    gdbus call --session \
             --dest org.freedesktop.Notifications \
             --object-path /org/freedesktop/Notifications \
             --method org.freedesktop.Notifications.Notify \
             Qobuz-wine 0 gtk-dialog-info \
             "Qobuz-wine" "Launching Qobuz in HW Shared (non-Exclusive) Mode" [] \
            "{'transient': <true>}" 5000 > /dev/null 2>&1

    #launch Qobuz
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $(dirname $wine_binary)/winecfg -v win7
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $wine_binary C:\\users\\$wine_username\\AppData\\Local\\Qobuz\\Qobuz.exe > $wine_prefix/drive_c/users/$wine_username/AppData/Roaming/Qobuz/wine.log 2>&1
fi
