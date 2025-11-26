#!/bin/bash
# Qobuz launcher script v 1.7 @Logon84 2025

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

    #launch Qobuz
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $(dirname $wine_binary)/winecfg -v win7
    env WINEPREFIX=$wine_prefix WINEDEBUG=fixme-winediag $wine_binary C:\\users\\$wine_username\\AppData\\Local\\Qobuz\\Qobuz.exe > $wine_prefix/drive_c/users/$wine_username/AppData/Roaming/Qobuz/wine.log 2>&1

    #get pipewire object id associated with Qobuz wine node
    qobuz_pid=""
    while [ -z "$qobuz_pid" ]; do
        sleep 0.1
        qobuz_pid=$(ps -e -o pid,comm | grep CrBrowserMain | awk {'print$1'})
    done
    qobuz_pipewire_interface_id=$(pw-dump | jq '.[] | select(.info.props."pipewire.sec.pid"=='"${qobuz_pid}"') | .info.props."object.id"')
    qobuz_wine_stream_id=$(pw-dump | jq '.[] | select(.info.props."client.id"=='"${qobuz_pipewire_interface_id}"') | .info.props."object.id"')

    #get current default sink id
    speakers_sink_id=$(wpctl status -n | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a '*' | awk '{print ($3+0)}')

    # Create a new null output sink
    pw-cli create-node adapter '{ factory.name=support.null-audio-sink node.nick='"${qobuz_wine_stream_id}@${speakers_sink_id}"' node.name="Null Output" node.description="Null Output" media.class=Audio/Sink object.linger=true audio.position=[FL FR] }'
    null_sink_id=$(wpctl status | grep "Null Output" | tr -d "*" | awk '{print ($2+0)}')

    #set null output as default
    wpctl set-default $null_sink_id

    #run autolinker script
    wpexec "$HOME/.config/wireplumber/scripts/steam-wire.lua" &
    lua_script_pid=$!

    #link Qobuz wine node to output sink only first time (next time is automatic by lua script)
    in_port1=$(pw-dump | jq '.[] | select(.info.props."node.id"=='"${speakers_sink_id}"' and .info.props."port.direction"=="in") | .info.props."port.id"' | head -n 1 | tr -d "\"")
    in_port2=$(pw-dump | jq '.[] | select(.info.props."node.id"=='"${speakers_sink_id}"' and .info.props."port.direction"=="in") | .info.props."port.id"' | tail -n 1 | tr -d "\"")
    
    out_port1=$(pw-dump | jq '.[] | select(.info.props."node.id"=='"${qobuz_wine_stream_id}"' and .info.props."port.direction"=="out") | .info.props."port.id"' | head -n 1 | tr -d "\"")
    out_port2=$(pw-dump | jq '.[] | select(.info.props."node.id"=='"${qobuz_wine_stream_id}"' and .info.props."port.direction"=="out") | .info.props."port.id"' | tail -n 1 | tr -d "\"")

    pw-cli create-link $qobuz_wine_stream_id $out_port1 $speakers_sink_id $in_port1 object.linger=1
    pw-cli create-link $qobuz_wine_stream_id $out_port2 $speakers_sink_id $in_port2 object.linger=1

    #Wait for closing qobuz
    ( tail -f -n0 $wine_prefix/drive_c/users/$wine_username/AppData/Roaming/Qobuz/wine.log & ) | grep -Eq "$exit_text"
    echo -e "\n\n\n\nClosing....\n\n\n\n"

    #destroy null output virtual device
    pw-cli destroy $null_sink_id

    #set default hw as it was before opening Qobuz
    wpctl set-default $speakers_sink_id

    #kill lua script
    kill -9 $lua_script_pid

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