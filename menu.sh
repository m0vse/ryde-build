#!/bin/bash

# Ryde Menu Application

##########################YAML PARSER ####################
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_.-]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
      if(length($2)== 0){  vname[indent]= ++idx[indent] };
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) { vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, vname[indent], $3);
      }
   }'
}
#########################################################


do_update()
{
  /home/pi/ryde-build/check_for_update.sh
}

do_info()
{
  /home/pi/ryde-build/display_info.sh
}


do_Set_RC_Type()
{
  RC_FILE=""

  menuchoice=$(whiptail --title "Set Remote Control Model" --menu "Select Choice" 30 78 20 \
    "1 Virgin" "Virgin Media"  \
    "2 Nebula" "Nebula DigiTV DVB-T USB Receiver" \
    "3 DVB-T2-S2" "eBay DVB-T2-S2 Combo with 12v in " \
    "4 LG TV " "LG 42 inch TV " \
    "5 LG Blu-Ray 1" "LG Blu-Ray Disc Player BP-530R " \
    "6 LG Blu-Ray 2" "LG Blu-Ray Disc Player BP-620R " \
    "7 Samsung TV" "Samsung 32 inch TV" \
    "8 Elekta TV" "Elekta Bravo 19 inch TV" \
    "9 WDTV Live" "WDTV Live Media Player" \
    "10 Hauppauge 1" "Hauppauge MediaMVP Network Media Player" \
    "11 Hauppauge 2" "Hauppauge USB PVR Ex-digilite" \
    "12 TS-1 Sat" "Technosat TS-1 Satellite Receiver" \
    "13 TS-3500" "Technosat TS-3500 Satellite Receiver" \
    "14 F-2100 Uni" "Digi-Wav 2 Pound F2100 Universal Remote" \
    "15 SF8008" "Octagon SF8008 Sat RX Remote" \
    "16 Freesat V7" "Freesat V7 Combo - Some keys changed" \
    "17 RTL-SDR" "RTL-SDR Basic Remote" \
    "18 Avermedia" "AverMedia PC Card Tuner" \
    "19 AEG DVD" "German AEG DVD Remote" \
    "20 G-RCU-023" "German Remote from an Opticum HD AX150, labelled G-RCU-023" \
    "21 Exit" "Exit without changing remote control model" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) RC_FILE="virgin" ;;
        2\ *) RC_FILE="nebula_usb" ;;
        3\ *) RC_FILE="hd-dvb-t2-s2-rx" ;;
        4\ *) RC_FILE="lg_tv_42" ;;
        5\ *) RC_FILE="lg_bluray-BP530" ;;
        6\ *) RC_FILE="lg_bluray-BP620" ;;
        7\ *) RC_FILE="samsung_32" ;;
        8\ *) RC_FILE="elekta_tv" ;;
        9\ *) RC_FILE="wdtv_live" ;;
        10\ *) RC_FILE="hauppauge_mvp" ;;
        11\ *) RC_FILE="hauppauge_usb" ;;
        12\ *) RC_FILE="ts1_sat" ;;
        13\ *) RC_FILE="ts3500_sat" ;;
        14\ *) RC_FILE="f2100_uni" ;;
        15\ *) RC_FILE="sf8008" ;;
        16\ *) RC_FILE="freesat_v7" ;;
        17\ *) RC_FILE="rtl0" ;;
        18\ *) RC_FILE="avermediacard" ;;
        19\ *) RC_FILE="aeg_dvd" ;;
        20\ *) RC_FILE="g_rcu_023" ;;
        21\ *) RC_FILE="exit" ;;
    esac

  if [ "$RC_FILE" != "exit" ]; then # Amend the config file

    RC_FILE="        - ${RC_FILE}"
    sed -i "/handsets:/{n;s/.*/$RC_FILE/}" /home/pi/ryde/config.yaml

    # Load the requested file
    #cp /home/pi/RydeHandsets/definitions/"$RC_FILE" /home/pi/ryde/handset.yaml

    # Set the requested protocol setting
    #sudo ir-keytable -p $PROTOCOL >/dev/null 2>/dev/null

    # And change it for the future
    #sed -i "/ir-keytable/c\sudo ir-keytable -p $PROTOCOL >/dev/null 2>/dev/null" /home/pi/ryde-build/rx.sh
  fi
}

do_Set_Freq()
{
  PRESET_FREQ=0
  PRESET_SCAN_FREQ_1=0
  PRESET_SCAN_FREQ_2=0
  PRESET_SCAN_FREQ_3=0
  PRESET_SCAN_FREQ_4=0

  # Read and trim the preset FREQ Values
  PRESET_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq=)"
  if [ "$PRESET_FREQ_LINE" != "" ]; then
    PRESET_FREQ="$(echo "$PRESET_FREQ_LINE" | sed "s/presets__"$AMEND_PRESET"__freq=\"//" | sed 's/\"//')"
    SCAN_FREQ_VALUES=0
  else
    PRESET_SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_1=)"
    if [ "$PRESET_SCAN_FREQ_1_LINE" != "" ]; then
      PRESET_SCAN_FREQ_1="$(echo "$PRESET_SCAN_FREQ_1_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_1=\"//" | sed 's/\"//')"
      SCAN_FREQ_VALUES=1
      PRESET_SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_2=)"
      if [ "$PRESET_SCAN_FREQ_2_LINE" != "" ]; then
        PRESET_SCAN_FREQ_2="$(echo "$PRESET_SCAN_FREQ_2_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_2=\"//" | sed 's/\"//')"
        SCAN_FREQ_VALUES=2
        PRESET_SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_3=)"
        if [ "$PRESET_SCAN_FREQ_3_LINE" != "" ]; then
          PRESET_SCAN_FREQ_3="$(echo "$PRESET_SCAN_FREQ_3_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_3=\"//" | sed 's/\"//')"
          SCAN_FREQ_VALUES=3
          PRESET_SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_4=)"
          if [ "$PRESET_SCAN_FREQ_4_LINE" != "" ]; then
            PRESET_SCAN_FREQ_4="$(echo "$PRESET_SCAN_FREQ_4_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_4=\"//" | sed 's/\"//')"
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi

  if [ "$SCAN_FREQ_VALUES" != "0" ]; then  # In scanning FREQ mode, so convert back to single FREQ
    
    # Set the preset FREQ to the first scanning FREQ
    PRESET_FREQ=$PRESET_SCAN_FREQ_1

    # Delete the scanning FREQ lines
    if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=3  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=2  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "2" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=1  # and decrement the number of rows
    fi
    if [ "$SCAN_FREQ_VALUES" == "1" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n;n;d" /home/pi/ryde/config.yaml
      SCAN_FREQ_VALUES=0  # and decrement the number of rows
    fi

    # Delete the first line that just said "        frequency:"
    sed -i "/^    "$AMEND_PRESET":/!b;n;d" /home/pi/ryde/config.yaml
    # Insert a new frequency line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;};a \        freq: $PRESET_FREQ" /home/pi/ryde/config.yaml
  fi

  PRESET_FREQ=$(whiptail --inputbox "Enter the new $AMEND_PRESET preset frequency in kHz" 8 78 $PRESET_FREQ --title "Frequency Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Delete the first line that just said "        frequency:"
    sed -i "/^    "$AMEND_PRESET":/!b;n;d" /home/pi/ryde/config.yaml
    # Insert a new frequency line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;};a \        freq: $PRESET_FREQ" /home/pi/ryde/config.yaml
  fi
}

do_Set_Scan_Freq()
{
  PRESET_FREQ=0
  PRESET_SCAN_FREQ_1=0
  PRESET_SCAN_FREQ_2=0
  PRESET_SCAN_FREQ_3=0
  PRESET_SCAN_FREQ_4=0

  # Read and trim the preset FREQ Values
  PRESET_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq=)"
  if [ "$PRESET_FREQ_LINE" != "" ]; then
    PRESET_FREQ="$(echo "$PRESET_FREQ_LINE" | sed "s/presets__"$AMEND_PRESET"__freq=\"//" | sed 's/\"//')"
    SCAN_FREQ_VALUES=0
  else
    PRESET_SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_1=)"
    if [ "$PRESET_SCAN_FREQ_1_LINE" != "" ]; then
      PRESET_SCAN_FREQ_1="$(echo "$PRESET_SCAN_FREQ_1_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_1=\"//" | sed 's/\"//')"
      SCAN_FREQ_VALUES=1
      PRESET_SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_2=)"
      if [ "$PRESET_SCAN_FREQ_2_LINE" != "" ]; then
        PRESET_SCAN_FREQ_2="$(echo "$PRESET_SCAN_FREQ_2_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_2=\"//" | sed 's/\"//')"
        SCAN_FREQ_VALUES=2
        PRESET_SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_3=)"
        if [ "$PRESET_SCAN_FREQ_3_LINE" != "" ]; then
          PRESET_SCAN_FREQ_3="$(echo "$PRESET_SCAN_FREQ_3_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_3=\"//" | sed 's/\"//')"
          SCAN_FREQ_VALUES=3
          PRESET_SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_4=)"
          if [ "$PRESET_SCAN_FREQ_4_LINE" != "" ]; then
            PRESET_SCAN_FREQ_4="$(echo "$PRESET_SCAN_FREQ_4_LINE" | sed "s/presets__"$AMEND_PRESET"__freq_4=\"//" | sed 's/\"//')"
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi

  # Convert to multi-FREQ format if single freq
  if [ "$SCAN_FREQ_VALUES" == 0 ]; then
    # Delete the first line that had the frequency value on it
    sed -i "/^    "$AMEND_PRESET":/!b;n;d" /home/pi/ryde/config.yaml
    # Insert a new blank frequency line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;};a \        freq:" /home/pi/ryde/config.yaml
    # Create the blank second line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;};n;a \          -" /home/pi/ryde/config.yaml
    # Put the previous single freq on the second line
    sed -i "/^    "$AMEND_PRESET":/!b;n;n;c\          - $PRESET_FREQ" /home/pi/ryde/config.yaml
    # So now the file is as if it was set up for multiples, but with one value
    SCAN_FREQ_VALUES=1
    PRESET_SCAN_FREQ_1=$PRESET_FREQ
  fi

  # Amend FREQ 1

  PRESET_SCAN_FREQ_1=$(whiptail --inputbox "Enter the first frequency in kHz" 8 78 $PRESET_SCAN_FREQ_1 --title "Frequency 1 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Put it on the second line
    sed -i "/^    "$AMEND_PRESET":/!b;n;n;c\          - $PRESET_SCAN_FREQ_1" /home/pi/ryde/config.yaml
  fi

  # At this stage FREQ1 has been entered, so ask for FREQ 2

  PRESET_SCAN_FREQ_2=$(whiptail --inputbox "Enter the second frequency in kHz (enter 0 for no more freqs)" 8 78 $PRESET_SCAN_FREQ_2 --title "Frequency 2 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then  # value has been changed
    if [ "$SCAN_FREQ_VALUES" == "1" ] ; then  # Previously only a single FREQ
      if [ "$PRESET_SCAN_FREQ_2" != "0" ]; then      # new valid FREQ entered (else do nothing)
        # row 3 does not exist, so create it
        sed -i "/^    "$AMEND_PRESET":/!{p;d;};n;n;a \          -" /home/pi/ryde/config.yaml
        # Put FREQ 2 on the third line
        sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;c\          - $PRESET_SCAN_FREQ_2" /home/pi/ryde/config.yaml
        SCAN_FREQ_VALUES=2
      fi
    else                                    # Previously multiple FREQs
      if [ "$PRESET_SCAN_FREQ_2" != "0" ]; then      # new valid FREQ entered, so now at least 2 freqs
        # so replace row 3 with new $PRESET_SCAN_FREQ_2
        sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;c\          - $PRESET_SCAN_FREQ_2" /home/pi/ryde/config.yaml
      else                                  # no more scanning FREQs, so delete 2nd 3rd and 4th freqs
        if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=3  # and decrement the number of rows
        fi
        if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=2  # and decrement the number of rows
        fi
        if [ "$SCAN_FREQ_VALUES" == "2" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_FREQ_VALUES=1  # and decrement the number of rows
        fi
      fi
    fi
  fi

  # At this stage FREQ2 has been entered, or SCAN_FREQ_VALUES=1 and we will do nothing more
  if [ "$SCAN_FREQ_VALUES" != "1" ]; then
    PRESET_SCAN_FREQ_3=$(whiptail --inputbox "Enter the third frequency in kHz (enter 0 for no more freqs)" 8 78 $PRESET_SCAN_FREQ_3 --title "Frequency 3 Entry Menu" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then  # value has been changed
      if [ "$SCAN_FREQ_VALUES" == "2" ] ; then  # Previously only 2 FREQs
        if [ "$PRESET_SCAN_FREQ_3" != "0" ]; then      # new valid FREQ entered (else do nothing)
          # row 4 does not exist, so create it
          sed -i "/^    "$AMEND_PRESET":/!{p;d;};n;n;n;a \          -" /home/pi/ryde/config.yaml
          # Put FREQ 3 on the 4th line
          sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;c\          - $PRESET_SCAN_FREQ_3" /home/pi/ryde/config.yaml
          # and set the FREQ scan values to 3
          SCAN_FREQ_VALUES=3
        fi
      else                                    # Previously multiple FREQs
        if [ "$PRESET_SCAN_FREQ_3" != "0" ]; then      # new valid FREQ entered
          # so replace row 4 with new $SCAN_FREQ_3
          sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;c\          - $PRESET_SCAN_FREQ_3" /home/pi/ryde/config.yaml
        else                                  # no more scanning FREQs, so delete lines
          if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 5
            sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_FREQ_VALUES=3  # and decrement the number of rows
          fi
          if [ "$SCAN_FREQ_VALUES" == "3" ]; then  # delete row 4
            sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_FREQ_VALUES=2  # and decrement the number of rows
          fi
        fi
      fi
    fi
    # At this stage FREQ3 has been entered, or SCAN_FREQ_VALUES=2 and we will do nothing more

    if [ "$SCAN_FREQ_VALUES" != "2" ]; then
      PRESET_SCAN_FREQ_4=$(whiptail --inputbox "Enter the fourth frequency in kHz (enter 0 for no more freqs)" 8 78 $PRESET_SCAN_FREQ_4 --title "Frequency 4 Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then  # value has been changed
        if [ "$SCAN_FREQ_VALUES" == "3" ] ; then  # Previously only 3 FREQs
          if [ "$PRESET_SCAN_FREQ_4" != "0" ]; then      # new valid FREQ entered (else do nothing)
            # row 5 does not exist, so create it
            sed -i "/^    "$AMEND_PRESET":/!{p;d;};n;n;n;n;a \          -" /home/pi/ryde/config.yaml
            # Put FREQ 4 on the 5th line
            sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;n;c\          - $PRESET_SCAN_FREQ_4" /home/pi/ryde/config.yaml
            # and set the FREQ scan values to 4
            SCAN_FREQ_VALUES=4
          fi
        else                                    # Previously 4 FREQs
          if [ "$PRESET_SCAN_FREQ_4" != "0" ]; then      # new valid FREQ entered
            # so replace row 5 with new $SCAN_FREQ_4
            sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;n;c\          - $PRESET_SCAN_FREQ_4" /home/pi/ryde/config.yaml
          else                                  # no more scanning FREQs, so delete lines
            if [ "$SCAN_FREQ_VALUES" == "4" ]; then  # delete row 5
              sed -i "/^    "$AMEND_PRESET":/!b;n;n;n;n;n;d" /home/pi/ryde/config.yaml
              SCAN_FREQ_VALUES=3  # and decrement the number of rows
            fi
          fi
        fi
      fi
    fi
  fi
}


do_Set_SR()
{
  #First, detect how may freq: lines there are

  PRESET_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq=)"
  if [ "$PRESET_FREQ_LINE" != "" ]; then
    SCAN_FREQ_VALUES=0
  else
    PRESET_SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_1=)"
    if [ "$PRESET_SCAN_FREQ_1_LINE" != "" ]; then
      SCAN_FREQ_VALUES=1
      PRESET_SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_2=)"
      if [ "$PRESET_SCAN_FREQ_2_LINE" != "" ]; then
        SCAN_FREQ_VALUES=2
        PRESET_SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_3=)"
        if [ "$PRESET_SCAN_FREQ_3_LINE" != "" ]; then
          SCAN_FREQ_VALUES=3
          PRESET_SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_4=)"
          if [ "$PRESET_SCAN_FREQ_4_LINE" != "" ]; then
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi
  # 0 means 1 line, 1 means 2 etc

 # Now create a pad element that counts down that many lines
  PAD=";n"
  case "$SCAN_FREQ_VALUES" in
    "0") PAD=";n" ;;
    "1") PAD=";n;n" ;;
    "2") PAD=";n;n;n" ;;
    "3") PAD=";n;n;n;n" ;;
    "4") PAD=";n;n;n;n;n" ;;
  esac

  DEFAULT_SR=0
  SCAN_SR_1=0
  SCAN_SR_2=0
  SCAN_SR_3=0
  SCAN_SR_4=0

  # Read and trim the preset SR Values
  PRESET_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr=)"
  if [ "$PRESET_SR_LINE" != "" ]; then
    PRESET_SR="$(echo "$PRESET_SR_LINE" | sed "s/presets__"$AMEND_PRESET"__sr=\"//" | sed 's/\"//')"
    SCAN_SR_VALUES=0
  else
    PRESET_SCAN_SR_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_1=)"
    if [ "$PRESET_SCAN_SR_1_LINE" != "" ]; then
      PRESET_SCAN_SR_1="$(echo "$PRESET_SCAN_SR_1_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_1=\"//" | sed 's/\"//')"
      SCAN_SR_VALUES=1
      PRESET_SCAN_SR_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_2=)"
      if [ "$PRESET_SCAN_SR_2_LINE" != "" ]; then
        PRESET_SCAN_SR_2="$(echo "$PRESET_SCAN_SR_2_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_2=\"//" | sed 's/\"//')"
        SCAN_SR_VALUES=2
        PRESET_SCAN_SR_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_3=)"
        if [ "$PRESET_SCAN_SR_3_LINE" != "" ]; then
          PRESET_SCAN_SR_3="$(echo "$PRESET_SCAN_SR_3_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_3=\"//" | sed 's/\"//')"
          SCAN_SR_VALUES=3
          PRESET_SCAN_SR_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_4=)"
          if [ "$PRESET_SCAN_SR_4_LINE" != "" ]; then
            PRESET_SCAN_SR_4="$(echo "$PRESET_SCAN_SR_4_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_4=\"//" | sed 's/\"//')"
            SCAN_SR_VALUES=4
          fi
        fi
      fi
    fi
  fi

  if [ "$SCAN_SR_VALUES" != "0" ]; then  # In scanning SR mode, so convert back to single SR
    
    # Set the preset SR to the first scanning SR
    PRESET_SR=$PRESET_SCAN_SR_1

    # Delete the scanning SR lines
    if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=3  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=2  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "2" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=1  # and decrement the number of rows
    fi
    if [ "$SCAN_SR_VALUES" == "1" ]; then  # delete row 3
      sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";n;d" /home/pi/ryde/config.yaml
      SCAN_SR_VALUES=0  # and decrement the number of rows
    fi

    # Delete the first line that just said "        sr:"
    sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";d" /home/pi/ryde/config.yaml
    # Insert a new sr line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";a \        sr:   $PRESET_SR" /home/pi/ryde/config.yaml
  fi

  PRESET_SR=$(whiptail --inputbox "Enter the new $AMEND_PRESET preset SR in kS" 8 78 $PRESET_SR --title "Symbol Rate Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Delete the first line that just said "        sr:"
    sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";d" /home/pi/ryde/config.yaml
    # Insert a new sr line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";a \        sr:   $PRESET_SR" /home/pi/ryde/config.yaml
  fi
}

do_Set_Scan_SR()
{
  #First, detect how may freq: lines there are

  PRESET_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq=)"
  if [ "$PRESET_FREQ_LINE" != "" ]; then
    SCAN_FREQ_VALUES=0
  else
    PRESET_SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_1=)"
    if [ "$PRESET_SCAN_FREQ_1_LINE" != "" ]; then
      SCAN_FREQ_VALUES=1
      PRESET_SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_2=)"
      if [ "$PRESET_SCAN_FREQ_2_LINE" != "" ]; then
        SCAN_FREQ_VALUES=2
        PRESET_SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_3=)"
        if [ "$PRESET_SCAN_FREQ_3_LINE" != "" ]; then
          SCAN_FREQ_VALUES=3
          PRESET_SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_4=)"
          if [ "$PRESET_SCAN_FREQ_4_LINE" != "" ]; then
            SCAN_FREQ_VALUES=4
          fi
        fi
      fi
    fi
  fi
  # 0 means 1 line, 1 means 2 etc

 # Now create a pad element that counts down that many lines
  PAD=";n"
  case "$SCAN_FREQ_VALUES" in
    "0") PAD=";n" ;;
    "1") PAD=";n;n" ;;
    "2") PAD=";n;n;n" ;;
    "3") PAD=";n;n;n;n" ;;
    "4") PAD=";n;n;n;n;n" ;;
  esac

  DEFAULT_SR=0
  SCAN_SR_1=0
  SCAN_SR_2=0
  SCAN_SR_3=0
  SCAN_SR_4=0

  # Read and trim the preset SR Values
  PRESET_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr=)"
  if [ "$PRESET_SR_LINE" != "" ]; then
    PRESET_SR="$(echo "$PRESET_SR_LINE" | sed "s/presets__"$AMEND_PRESET"__sr=\"//" | sed 's/\"//')"
    SCAN_SR_VALUES=0
  else
    PRESET_SCAN_SR_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_1=)"
    if [ "$PRESET_SCAN_SR_1_LINE" != "" ]; then
      PRESET_SCAN_SR_1="$(echo "$PRESET_SCAN_SR_1_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_1=\"//" | sed 's/\"//')"
      SCAN_SR_VALUES=1
      PRESET_SCAN_SR_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_2=)"
      if [ "$PRESET_SCAN_SR_2_LINE" != "" ]; then
        PRESET_SCAN_SR_2="$(echo "$PRESET_SCAN_SR_2_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_2=\"//" | sed 's/\"//')"
        SCAN_SR_VALUES=2
        PRESET_SCAN_SR_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_3=)"
        if [ "$PRESET_SCAN_SR_3_LINE" != "" ]; then
          PRESET_SCAN_SR_3="$(echo "$PRESET_SCAN_SR_3_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_3=\"//" | sed 's/\"//')"
          SCAN_SR_VALUES=3
          PRESET_SCAN_SR_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_4=)"
          if [ "$PRESET_SCAN_SR_4_LINE" != "" ]; then
            PRESET_SCAN_SR_4="$(echo "$PRESET_SCAN_SR_4_LINE" | sed "s/presets__"$AMEND_PRESET"__sr_4=\"//" | sed 's/\"//')"
            SCAN_SR_VALUES=4
          fi
        fi
      fi
    fi
  fi

  # Convert to multi-SR format if in single-SR format
  if [ "$SCAN_SR_VALUES" == 0 ]; then
    # Delete the first line that had the SR value on it
    sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;d" /home/pi/ryde/config.yaml
    # Insert a new blank sr line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";a \        sr:" /home/pi/ryde/config.yaml
    # Create the blank second line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";n;a \          -" /home/pi/ryde/config.yaml
    # Put the previous single sr on the second line
    sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";n;c\          - $PRESET_SR" /home/pi/ryde/config.yaml
    # So now the file is as if it was set up for multiples, but with one value
    SCAN_SR_VALUES=1
    PRESET_SCAN_SR_1=$PRESET_SR
  fi

  # Amend SR 1

  PRESET_SCAN_SR_1=$(whiptail --inputbox "Enter the first SR in kS" 8 78 $PRESET_SCAN_SR_1 --title "Symbol Rate 1 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    # Put it on the second line
    sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;c\          - $PRESET_SCAN_SR_1" /home/pi/ryde/config.yaml
  fi

  # At this stage SR1 has been entered, so ask for SR 2

  PRESET_SCAN_SR_2=$(whiptail --inputbox "Enter the second SR in kS (enter 0 for no more SRs)" 8 78 $PRESET_SCAN_SR_2 --title "Symbol Rate 2 Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then  # value has been changed
    if [ "$SCAN_SR_VALUES" == "1" ] ; then  # Previously only a single SR
      if [ "$PRESET_SCAN_SR_2" != "0" ]; then      # new valid SR entered (else do nothing)
        # row 3 does not exist, so create it
        sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";n;n;a \          -" /home/pi/ryde/config.yaml
        # Put SR 2 on the third line
        sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;c\          - $PRESET_SCAN_SR_2" /home/pi/ryde/config.yaml
        SCAN_SR_VALUES=2
      fi
    else                                    # Previously multiple SRs
      if [ "$PRESET_SCAN_SR_2" != "0" ]; then      # new valid SR entered, so now at least 2 srs
        # so replace row 3 with new $PRESET_SCAN_SR_2
        sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;c\          - $PRESET_SCAN_SR_2" /home/pi/ryde/config.yaml
      else                                  # no more scanning SRs, so delete 2nd 3rd and 4th SRs
        if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=3  # and decrement the number of rows
        fi
        if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=2  # and decrement the number of rows
        fi
        if [ "$SCAN_SR_VALUES" == "2" ]; then  # delete row 4
          sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;d" /home/pi/ryde/config.yaml
          SCAN_SR_VALUES=1  # and decrement the number of rows
        fi
      fi
    fi
  fi

  # At this stage SR2 has been entered, or SCAN_SR_VALUES=1 and we will do nothing more
  if [ "$SCAN_SR_VALUES" != "1" ]; then
    PRESET_SCAN_SR_3=$(whiptail --inputbox "Enter the third SR in kS (enter 0 for no more SRs)" 8 78 $PRESET_SCAN_SR_3 --title "Symbol Rate 3 Entry Menu" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then  # value has been changed
      if [ "$SCAN_SR_VALUES" == "2" ] ; then  # Previously only 2 SRs
        if [ "$PRESET_SCAN_SR_3" != "0" ]; then      # new valid SR entered (else do nothing)
          # row 4 does not exist, so create it
          sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";n;n;n;a \          -" /home/pi/ryde/config.yaml
          # Put SR 3 on the 4th line
          sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;c\          - $PRESET_SCAN_SR_3" /home/pi/ryde/config.yaml
          # and set the SR scan values to 3
          SCAN_SR_VALUES=3
        fi
      else                                    # Previously multiple SRs
        if [ "$PRESET_SCAN_SR_3" != "0" ]; then      # new valid SR entered
          # so replace row 4 with new $SCAN_SR_3
          sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;c\          - $PRESET_SCAN_SR_3" /home/pi/ryde/config.yaml
        else                                  # no more scanning SRs, so delete lines
          if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 5
            sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_SR_VALUES=3  # and decrement the number of rows
          fi
          if [ "$SCAN_SR_VALUES" == "3" ]; then  # delete row 4
            sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;d" /home/pi/ryde/config.yaml
            SCAN_SR_VALUES=2  # and decrement the number of rows
          fi
        fi
      fi
    fi
    # At this stage SR3 has been entered, or SCAN_SR_VALUES=2 and we will do nothing more

    if [ "$SCAN_SR_VALUES" != "2" ]; then
      PRESET_SCAN_SR_4=$(whiptail --inputbox "Enter the fourth SR in kS (enter 0 for no more SRs)" 8 78 $PRESET_SCAN_SR_4 --title "Symbol Rate 4 Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then  # value has been changed
        if [ "$SCAN_SR_VALUES" == "3" ] ; then  # Previously only 3 SRs
          if [ "$PRESET_SCAN_SR_4" != "0" ]; then      # new valid SR entered (else do nothing)
            # row 5 does not exist, so create it
            sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";n;n;n;n;a \          -" /home/pi/ryde/config.yaml
            # Put SR 4 on the 5th line
            sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;n;c\          - $PRESET_SCAN_SR_4" /home/pi/ryde/config.yaml
            # and set the SR scan values to 4
            SCAN_SR_VALUES=4
          fi
        else                                    # Previously 4 SRs
          if [ "$PRESET_SCAN_SR_4" != "0" ]; then      # new valid SR entered
            # so replace row 5 with new $SCAN_SR_4
            sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;n;c\          - $PRESET_SCAN_SR_4" /home/pi/ryde/config.yaml
          else                                  # no more scanning SRs, so delete lines
            if [ "$SCAN_SR_VALUES" == "4" ]; then  # delete row 5
              sed -i "/^    "$AMEND_PRESET":/!b"$PAD";n;n;n;n;n;d" /home/pi/ryde/config.yaml
              SCAN_SR_VALUES=3  # and decrement the number of rows
            fi
          fi
        fi
      fi
    fi
  fi
}

do_Set_Preset_Band()
{
  BAND_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__band=)"
  BAND="$(echo "$BAND_LINE" | sed "s/presets__"$AMEND_PRESET"__band=\"//" | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF
  Radio3=OFF
  Radio4=OFF
  Radio5=OFF
  Radio6=OFF
  Radio7=OFF
  Radio8=OFF

  case "$BAND" in
    "*bandlnblow")
      Radio1=ON
    ;;
    "*band146")
      Radio2=ON
    ;;
    "*band437")
      Radio3=ON
    ;;
    "*band1255")
      Radio4=ON
    ;;
    "*band2400")
      Radio5=ON
    ;;
    "*band3400")
      Radio6=ON
    ;;
    "*band5760")
      Radio7=ON
    ;;
    "*band10368")
      Radio8=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac

  NEW_BAND=$(whiptail --title "Select the new $AMEND_PRESET preset band" --radiolist \
    "Select Choice" 20 78 10 \
    "QO-100" "QO-100 Band" $Radio1 \
    "146" "146 MHz Band" $Radio2 \
    "437" "437 MHz Band" $Radio3 \
    "1255" "1255 MHz Band" $Radio4 \
    "2400" "2400 MHz Band" $Radio5 \
    "3400" "3400 MHz Band" $Radio6 \
    "5760" "5760 MHz Band" $Radio7 \
    "10368" "10368 MHz Band" $Radio8 \
    3>&2 2>&1 1>&3)

  if [ $? -eq 0 ]; then  # The band has changed, so amend it
    case "$NEW_BAND" in
      "QO-100")
        NEW_BAND=*bandlnblow
      ;;
      "146")
        NEW_BAND=*band146
      ;;
      "437")
        NEW_BAND=*band437
      ;;
      "1255")
        NEW_BAND=*band1255
      ;;
      "2400")
        NEW_BAND=*band2400
      ;;
      "3400")
        NEW_BAND=*band3400
      ;;
      "5760")
        NEW_BAND=*band5760
      ;;
      "10368")
      NEW_BAND=*band10368
      ;;
    esac

    # First, detect how may freq: lines there are

    PRESET_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq=)"
    if [ "$PRESET_FREQ_LINE" != "" ]; then
      SCAN_FREQ_VALUES=0
    else
      PRESET_SCAN_FREQ_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_1=)"
      if [ "$PRESET_SCAN_FREQ_1_LINE" != "" ]; then
        SCAN_FREQ_VALUES=1
        PRESET_SCAN_FREQ_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_2=)"
        if [ "$PRESET_SCAN_FREQ_2_LINE" != "" ]; then
          SCAN_FREQ_VALUES=2
          PRESET_SCAN_FREQ_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_3=)"
          if [ "$PRESET_SCAN_FREQ_3_LINE" != "" ]; then
            SCAN_FREQ_VALUES=3
            PRESET_SCAN_FREQ_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__freq_4=)"
            if [ "$PRESET_SCAN_FREQ_4_LINE" != "" ]; then
              SCAN_FREQ_VALUES=4
            fi
          fi
        fi
      fi
    fi
    # 0 means 1 line, 1 means 2 etc

    # Next, detect how may sr: lines there are

    PRESET_SR_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr=)"
    if [ "$PRESET_SR_LINE" != "" ]; then
      SCAN_SR_VALUES=0
    else
      PRESET_SCAN_SR_1_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_1=)"
      if [ "$PRESET_SCAN_SR_1_LINE" != "" ]; then
        SCAN_SR_VALUES=1
        PRESET_SCAN_SR_2_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_2=)"
        if [ "$PRESET_SCAN_SR_2_LINE" != "" ]; then
          SCAN_SR_VALUES=2
          PRESET_SCAN_SR_3_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_3=)"
          if [ "$PRESET_SCAN_SR_3_LINE" != "" ]; then
            SCAN_SR_VALUES=3
            PRESET_SCAN_SR_4_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep presets__"$AMEND_PRESET"__sr_4=)"
            if [ "$PRESET_SCAN_SR_4_LINE" != "" ]; then
              SCAN_SR_VALUES=4
            fi
          fi
        fi
      fi
    fi
    # 0 means 1 line, 1 means 2 etc

    # Add the SR and Freq Lines:
    let "VALUES=$SCAN_FREQ_VALUES + $SCAN_SR_VALUES + 1"

    # Now create a pad element that counts down that many lines
    PAD=";n"
    case "$VALUES" in
      "0") PAD=";n" ;;
      "1") PAD=";n;n" ;;
      "2") PAD=";n;n;n" ;;
      "3") PAD=";n;n;n;n" ;;
      "4") PAD=";n;n;n;n;n" ;;
      "5") PAD=";n;n;n;n;n;n" ;;
      "6") PAD=";n;n;n;n;n;n;n" ;;
      "7") PAD=";n;n;n;n;n;n;n;n" ;;
      "8") PAD=";n;n;n;n;n;n;n;n;n" ;;
      "9") PAD=";n;n;n;n;n;n;n;n;n;n" ;;
    esac

    # Delete the line that just said "        band:"
    sed -i "/^    "$AMEND_PRESET":/!b;n"$PAD";d" /home/pi/ryde/config.yaml
    # Insert a new band line
    sed -i "/^    "$AMEND_PRESET":/!{p;d;}"$PAD";a \        band: $NEW_BAND" /home/pi/ryde/config.yaml
  fi
}

do_Set_Presets()
{
  menuchoice=$(whiptail --title "Select Preset for Amendment" --menu "Select Choice" 20  78 11 \
    "1  QO-100_Beacon" "Amend details for the QO-100_Beacon preset" \
    "2  QO-100_9.25_333" "Amend details for the QO-100_9.25_333 preset" \
    "3  QO-100_Custom" "Amend details for the QO-100_Custom preset" \
    "4  QO-100_Scan" "Amend details for the QO-100_Scan preset" \
    "5  146.5_MHz_125" "Amend details for the 146.5_MHz_125 preset" \
    "6  146.5_MHz_333" "Amend details for the 146.5_MHz_333 preset" \
    "7  437.0_MHz_333" "Amend details for the 437.0_MHz_333 preset" \
    "8  437.0_MHz_1000" "Amend details for the 437.0_MHz_1000 preset" \
    "9  1255_MHz_333" "Amend details for the 1255_MHz_333 preset" \
    "10 1255_MHz_Custom" "Amend details for the 1255_MHz_Custom preset" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) AMEND_PRESET="QO-100_Beacon" ;;
      2\ *) AMEND_PRESET="QO-100_9.25_333"  ;;
      3\ *) AMEND_PRESET="QO-100_Custom" ;;
      4\ *) AMEND_PRESET="QO-100_Scan"  ;;
      5\ *) AMEND_PRESET="146.5_MHz_125" ;;
      6\ *) AMEND_PRESET="146.5_MHz_333"  ;;
      7\ *) AMEND_PRESET="437.0_MHz_333" ;;
      8\ *) AMEND_PRESET="437.0_MHz_1000"  ;;
      9\ *) AMEND_PRESET="1255_MHz_333" ;;
      10\ *) AMEND_PRESET="1255_MHz_Custom"  ;;
    esac

  do_Set_Preset_Band

  menuchoice=$(whiptail --title "Amend frequency details for the $AMEND_PRESET preset" --menu "Select Choice" 16 78 10 \
    "1 Freq" "Set a Single Receive Frequency" \
    "2 Scan Freqs" "Set Multiple Receive Frequencies for Scanning" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Set_Freq ;;
      2\ *) do_Set_Scan_Freq ;;
    esac

  menuchoice=$(whiptail --title "Amend SR details for the $AMEND_PRESET preset" --menu "Select Choice" 16 78 10 \
    "1 SR" "Set a Single Receive SR" \
    "2 Scan SRs" "Set Multiple Receive SRs for Scanning" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Set_SR ;;
      2\ *) do_Set_Scan_SR ;;
    esac

}


do_Check_RC_Codes()
{
  sudo ir-keytable -p all >/dev/null 2>/dev/null
  reset
  echo "After CTRL-C, type menu to get back to the Menu System"
  echo
  ir-keytable -t
}

do_Set_TSTimeout()
{
  # Read and trim the current TS Timeout
  TS_TIMEOUT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'longmynd__tstimeout=')"
  TS_TIMEOUT="$(echo "$TS_TIMEOUT_LINE" | sed 's/longmynd__tstimeout=\"//' | sed 's/\"//')"

  TS_TIMEOUT=$(whiptail --inputbox "Enter the new TS Timeout in mS (default 5000 - ie 5 seconds)" 8 78 $TS_TIMEOUT --title "TS TimeOut Entry Menu" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i "/    tstimeout:/c\    tstimeout: $TS_TIMEOUT" /home/pi/ryde/config.yaml
  fi
}

do_Restore_Factory()
{
  cp /home/pi/ryde-build/config.yaml /home/pi/ryde/config.yaml

  # Wait here until user presses a key
  whiptail --title "Factory Setting Restored" --msgbox "Touch any key to continue.  You will need to reselect your remote control type." 8 78
}

do_Debug_Menu()
{
  # Read and trim the current Debug Menu Setting
  DEBUG_MENU_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'debug__enableMenu=')"
  DEBUG_MENU="$(echo "$DEBUG_MENU_LINE" | sed 's/debug__enableMenu=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF
  case "$DEBUG_MENU" in
    "False")
      Radio1=ON
    ;;
    "True")
      Radio2=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac
  DEBUG_MENU=$(whiptail --title "Select Whether the Debug Menu is Displayed" --radiolist \
    "Select Choice" 20 78 5 \
    "False" "Debug Menu Not Displayed" $Radio1 \
    "True" "Debug Menu Displayed" $Radio2 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    sed -i "/    enableMenu:/c\    enableMenu: $DEBUG_MENU" /home/pi/ryde/config.yaml
  fi
}


do_Power_Button()
{
  # Read and trim the current Power Button Setting
  POWER_BUTTON_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'shutdownBehavior=')"
  POWER_BUTTON="$(echo "$POWER_BUTTON_LINE" | sed 's/shutdownBehavior=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF
  case "$POWER_BUTTON" in
    "APPSTOP")
      Radio1=ON
    ;;
    "APPREST")
      Radio2=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac
  POWER_BUTTON=$(whiptail --title "Select Action on Power Button Double Press" --radiolist \
    "Select Choice" 20 78 5 \
    "APPSTOP" "Ryde Application Stops, RPi keeps Running" $Radio1 \
    "APPREST" "Ryde Application Restarts" $Radio2 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    sed -i "/shutdownBehavior:/c\shutdownBehavior: $POWER_BUTTON" /home/pi/ryde/config.yaml
  fi
}

do_SD_Button()
{
  Radio1=OFF
  Radio2=OFF

  # Check current status
  # If /home/pi/.pi-sdn exists then it is loaded

  if test -f "/home/pi/.pi-sdn"; then
    Radio1=ON
  else
    Radio2=ON
  fi
  SD_BUTTON=$(whiptail --title "Select Hardware Shutdown Function" --radiolist \
    "Select Choice" 20 78 5 \
    "SHUTDOWN" "RPi Immediately Shuts Down" $Radio1 \
    "DO NOTHING" "Nothing happens" $Radio2 \
    3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    if [ "$SD_BUTTON" == "SHUTDOWN" ]; then
      cp /home/pi/ryde-build/text.pi-sdn /home/pi/.pi-sdn  ## Load it at logon
      /home/pi/.pi-sdn                                     ## Load it now
    else
      rm /home/pi/.pi-sdn >/dev/null 2>/dev/null           ## Stop it being loaded at log-on
      sudo pkill -x pi-sdn                                 ## kill the current process
    fi
  fi
}


do_Settings()
{
  menuchoice=$(whiptail --title "Advanced Settings Menu" --menu "Select Choice" 16 78 10 \
    "1 Tuner Timeout" "Adjust the Tuner Reset Time when no valid TS " \
    "2 Restore Factory" "Reset all settings to default" \
    "3 Debug Menu" "Enable or Disable the Debug Menu" \
    "4 Power Button" "Set behaviour on double press of power button" \
    "5 Hardware Shutdown" "Enable or disable hardware shudown function" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Set_TSTimeout ;;
      2\ *) do_Restore_Factory ;;
      3\ *) do_Debug_Menu ;;
      4\ *) do_Power_Button ;;
      5\ *) do_SD_Button ;;
    esac
}


do_Set_Bands()
{
  menuchoice=$(whiptail --title "Select band for Amendment" --menu "Select Choice" 16 78 10 \
    "1 QO-100" "Set the LNB Offset frequency for QO-100" \
    "2 146" "Amend details for the 146 MHz Band" \
    "3 437" "Amend details for the 437 MHz Band" \
    "4 1255" "Amend details for the 1255 MHz Band" \
    "5 2400" "Amend details for the 2400 MHz Band" \
    "6 3400" "Amend details for the 3400 MHz Band" \
    "7 5760" "Amend details for the 5760 MHz Band" \
    "8 10368" "Amend details for the 10368 MHz Band" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) AMEND_BAND="QO-100" ;;
      2\ *) AMEND_BAND="146"  ;;
      3\ *) AMEND_BAND="437" ;;
      4\ *) AMEND_BAND="1255"  ;;
      5\ *) AMEND_BAND="2400" ;;
      6\ *) AMEND_BAND="3400"  ;;
      7\ *) AMEND_BAND="5760" ;;
      8\ *) AMEND_BAND="10368"  ;;
    esac

  case "$AMEND_BAND" in
    "QO-100")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__QO-100__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__QO-100__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new QO-100 LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__QO-100__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__QO-100__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the QO-100 Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for QO-100)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    QO-100:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__QO-100__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__QO-100__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new QO-100 Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts (QO-100)" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__QO-100__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__QO-100__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new QO-100 Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__QO-100__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__QO-100__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new QO-100 Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    QO-100:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "146")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__146__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__146__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 146 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    146:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__146__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__146__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 146 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 146)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    146:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__146__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__146__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 146 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    146:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__146__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__146__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 146 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    146:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__146__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__146__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 146 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    146:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "437")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__437__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__437__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 437 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    437:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__437__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__437__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 437 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 437)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    437:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__437__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__437__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 437 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    437:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__437__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__437__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 437 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    437:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__437__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__437__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 437 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    437:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "1255")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__1255__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__1255__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 1255 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    1255:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__1255__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__1255__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 1255 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 1255)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    1255:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__1255__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__1255__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 1255 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    1255:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__1255__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__1255__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 1255 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    1255:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__1255__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__1255__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 1255 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    1255:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "2400")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__2400__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__2400__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 2400 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    2400:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__2400__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__2400__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 2400 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 2400)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    2400:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__2400__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__2400__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 2400 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    2400:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__2400__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__2400__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 2400 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    2400:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__2400__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__2400__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 2400 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    2400:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "3400")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__3400__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__3400__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 3400 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    3400:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__3400__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__3400__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 3400 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 3400)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    3400:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__3400__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__3400__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 3400 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    3400:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__3400__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__3400__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 3400 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    3400:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__3400__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__3400__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 3400 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    3400:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "5760")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__5760__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__5760__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 5760 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    5760:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__5760__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__5760__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 5760 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 5760)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    5760:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__5760__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__5760__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 5760 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    5760:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__5760__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__5760__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 5760 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    5760:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__5760__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__5760__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 5760 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    5760:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;
    "10368")
      # Read and trim the LO frequency
      LO_FREQ_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__10368__lofreq=')"
      LO_FREQ="$(echo "$LO_FREQ_LINE" | sed 's/bands__10368__lofreq=\"//' | sed 's/\"//')"
      LO_FREQ=$(whiptail --inputbox "Enter the new 10368 MHz Band LO frequency in kHz (for example 9750000)" 8 78 $LO_FREQ --title "LO Frequency Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    10368:/!b;n;c\        lofreq: $LO_FREQ" /home/pi/ryde/config.yaml
      fi

      # Read and trim the LO side
      LO_SIDE_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__10368__loside=')"
      LO_SIDE="$(echo "$LO_SIDE_LINE" | sed 's/bands__10368__loside=\"//' | sed 's/\"//')"
      if [ "$LO_FREQ" != "0" ]; then  # Set LO side
        Radio1=OFF
        Radio2=OFF
        case "$LO_SIDE" in
          "LOW")
            Radio1=ON
          ;;
          "HIGH")
            Radio2=ON
          ;;
          *)
            Radio1=ON
          ;;
        esac
        LO_SIDE=$(whiptail --title "Select the LO Side for the 10368 MHz Band" --radiolist \
          "Select Choice" 20 78 5 \
          "LOW" "LO frequency below signal frequency (normal for 10368)" $Radio1 \
          "HIGH" "LO frequency above signal frequency" $Radio2 \
          3>&2 2>&1 1>&3)
        if [ $? -eq 0 ]; then
          sed -i "/    10368:/!b;n;n;c\        loside: $LO_SIDE" /home/pi/ryde/config.yaml
        fi
      fi

      # Read and trim the polarity
      POL_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__10368__pol=')"
      POL="$(echo "$POL_LINE" | sed 's/bands__10368__pol=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      Radio3=OFF
      case "$POL" in
        "NONE")
          Radio1=ON
        ;;
        "VERTICAL")
          Radio2=ON
        ;;
        "HORIZONTAL")
          Radio3=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_POL=$(whiptail --title "Select the new 10368 MHz Band Polarity" --radiolist \
        "Select Choice" 20 78 5 \
        "NONE" "No LNB Voltage" $Radio1 \
        "VERTICAL" "Vertical Polarity 13 Volts" $Radio2 \
        "HORIZONTAL" "Horizontal Polarity 18 Volts" $Radio3 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    10368:/!b;n;n;n;c\        pol: $NEW_POL" /home/pi/ryde/config.yaml
      fi

      # Read and trim the port
      PORT_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__10368__port=')"
      PORT="$(echo "$PORT_LINE" | sed 's/bands__10368__port=\"//' | sed 's/\"//')"
      Radio1=OFF
      Radio2=OFF
      case "$PORT" in
        "TOP")
          Radio1=ON
        ;;
        "BOTTOM")
          Radio2=ON
        ;;
        *)
          Radio1=ON
        ;;
      esac
      NEW_PORT=$(whiptail --title "Select the new 10368 MHz Band Port" --radiolist \
        "Select Choice" 20 78 5 \
        "TOP" "Top LNB Port    (Socket A)" $Radio1 \
        "BOTTOM" "Bottom LNB Port (Socket B)" $Radio2 \
        3>&2 2>&1 1>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    10368:/!b;n;n;n;n;c\        port: $NEW_PORT" /home/pi/ryde/config.yaml
      fi

      # Read and trim the GPIO Band Setting
      GPIOID_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'bands__10368__gpioid=')"
      GPIOID="$(echo "$GPIOID_LINE" | sed 's/bands__10368__gpioid=\"//' | sed 's/\"//')"
      GPIOID=$(whiptail --inputbox "Enter the new 10368 MHz Band GPIO setting (0 - 7)" 8 78 \
      $GPIOID --title "Band GPIO Entry Menu" 3>&1 1>&2 2>&3)
      if [ $? -eq 0 ]; then
        sed -i "/    10368:/!b;n;n;n;n;n;c\        gpioid: $GPIOID" /home/pi/ryde/config.yaml
      fi
    ;;

  esac
}


do_Set_Defaults()
{
  # Read and trim the current start-up preset     default="*preset01"
  DEFAULT_PRESET_LINE="$(parse_yaml /home/pi/ryde/config.yaml | grep 'default=')"
  DEFAULT_PRESET="$(echo "$DEFAULT_PRESET_LINE" | sed 's/default=\"//' | sed 's/\"//')"

  Radio1=OFF
  Radio2=OFF
  Radio3=OFF
  Radio4=OFF
  Radio5=OFF
  Radio6=OFF
  Radio7=OFF
  Radio8=OFF
  Radio9=OFF
  Radio10=OFF

  case "$DEFAULT_PRESET" in
    "*preset01")
      Radio1=ON
    ;;
    "*preset02")
      Radio2=ON
    ;;
    "*preset03")
      Radio3=ON
    ;;
    "*preset04")
      Radio4=ON
    ;;
    "*preset05")
      Radio5=ON
    ;;
    "*preset06")
      Radio6=ON
    ;;
    "*preset07")
      Radio7=ON
    ;;
    "*preset08")
      Radio8=ON
    ;;
    "*preset09")
      Radio9=ON
    ;;
    "*preset10")
      Radio10=ON
    ;;
    *)
      Radio1=ON
    ;;
  esac
  
  NEW_DEFAULT_PRESET=$(whiptail --title "Select the new Default Preset" --radiolist \
    "Select Choice" 20 78 12 \
    "QO-100_Beacon" "The QO-100_Beacon preset" $Radio1 \
    "QO-100_9.25_333" "The QO-100_9.25_333 preset" $Radio2 \
    "QO-100_Custom" "The QO-100_Custom preset" $Radio3 \
    "QO-100_Scan" "The QO-100_Scan preset" $Radio4 \
    "146.5_MHz_125" "The 146.5_MHz_125 preset" $Radio5 \
    "146.5_MHz_333" "The 146.5_MHz_333 preset" $Radio6 \
    "437.0_MHz_333" "The 437.0_MHz_333 preset" $Radio7 \
    "437.0_MHz_1000" "The 437.0_MHz_1000 preset" $Radio8 \
    "1255_MHz_333" "The 1255_MHz_333 preset" $Radio9 \
    "1255_MHz_Custom" "The 1255_MHz_Custom preset" $Radio10 \
     3>&2 2>&1 1>&3)
  if [ $? -eq 0 ]; then
    case "$NEW_DEFAULT_PRESET" in
      "QO-100_Beacon") NEW_DEFAULT_PRESET="*preset01" ;;
      "QO-100_9.25_333") NEW_DEFAULT_PRESET="*preset02" ;;
      "QO-100_Custom") NEW_DEFAULT_PRESET="*preset03" ;;
      "QO-100_Scan") NEW_DEFAULT_PRESET="*preset04" ;;
      "146.5_MHz_125") NEW_DEFAULT_PRESET="*preset05" ;;
      "146.5_MHz_333") NEW_DEFAULT_PRESET="*preset06" ;;
      "437.0_MHz_333") NEW_DEFAULT_PRESET="*preset07" ;;
      "437.0_MHz_1000") NEW_DEFAULT_PRESET="*preset08" ;;
      "1255_MHz_333") NEW_DEFAULT_PRESET="*preset09" ;;
      "1255_MHz_Custom") NEW_DEFAULT_PRESET="*preset10" ;;
    esac
    sed -i "/^default: /c\default: $NEW_DEFAULT_PRESET" /home/pi/ryde/config.yaml
  fi
}


do_Reboot()
{
  sudo reboot now
}


do_Nothing()
{
  :
}


do_Norm_HDMI()
{
  # change #enable_tvout=1 or enable_tvout=1 to #enable_tvout=1

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#enable_tvout=1" is not there, so check if "enable_tvout=1" is there
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "enable_tvout=1" is there, so replace it with "#enable_tvout=1"
      sudo sed -i '/enable_tvout=1/c\#enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "#enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_Safe_HDMI()
{
  # change #enable_tvout=1 or enable_tvout=1 to #enable_tvout=1

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#enable_tvout=1" is not there, so check if "enable_tvout=1" is there
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "enable_tvout=1" is there, so replace it with "#enable_tvout=1"
      sudo sed -i '/enable_tvout=1/c\#enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "#enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  # change #hdmi_safe=1 or hdmi_safe=1 to hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#hdmi_safe=1" is there, so change it to "hdmi_safe=1"
    sudo sed -i '/#hdmi_safe=1/c\hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#hdmi_safe=1" is not there so check "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -ne 0 ]; then  # "hdmi_safe=1" is not there, so add it (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_Comp_Vid_PAL()
{
  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  #change #sdtv_mode=1/2 or sdtv_mode=1/2 to sdtv_mode=2

  # first check if "#sdtv_mode=2" is in /boot/config.txt
  grep -q "#sdtv_mode=2" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#sdtv_mode=2" is there, so change it to "sdtv_mode=2"
    sudo sed -i '/#sdtv_mode=2/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#sdtv_mode=2" is not there so check if "#sdtv_mode=1" is there
    grep -q "#sdtv_mode=1" /boot/config.txt
    if [ $? -eq 0 ]; then  #  "#sdtv_mode=1" is there, so change it to "sdtv_mode=2"
      sudo sed -i '/#sdtv_mode=1/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # neither "#sdtv_mode=2" nor "#sdtv_mode=1" are there
      grep -q "sdtv_mode=1" /boot/config.txt  # so check if "sdtv_mode=1" is there
      if [ $? -eq 0 ]; then  #  "sdtv_mode=1" is there, so change it to "sdtv_mode=2"
        sudo sed -i '/sdtv_mode=1/c\sdtv_mode=2' /boot/config.txt  >/dev/null 2>/dev/null
      else       # check if "sdtv_mode=2" is there and add it if not
        grep -q "sdtv_mode=2" /boot/config.txt  
        if [ $? -ne 0 ]; then  # "sdtv_mode=2" is not there, so add it at the end (else do nothing)
          sudo bash -c 'echo " " >> /boot/config.txt '
          sudo bash -c 'echo "# uncomment for composite PAL" >> /boot/config.txt '
          sudo bash -c 'echo "sdtv_mode=2" >> /boot/config.txt '
          sudo bash -c 'echo " " >> /boot/config.txt '
        fi
      fi
    fi
  fi

  # change #enable_tvout=1 or enable_tvout=1 to enable_tvout=1 (Add if not present)

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -eq 0 ]; then  # "#enable_tvout=1" is there, so replace it with "enable_tvout=1"
    sudo sed -i '/#enable_tvout=1/c\enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#enable_tvout=1" is not there, so check for "enable_tvout=1"
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -ne 0 ]; then  #  "enable_tvout=1" is not there, so add it at the end (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_Comp_Vid_NTSC()
{
  # change #hdmi_safe=1 or hdmi_safe=1 to #hdmi_safe=1

  # first check if "#hdmi_safe=1" is in /boot/config.txt
  grep -q "#hdmi_safe=1" /boot/config.txt
  if [ $? -ne 0 ]; then  #  "#hdmi_safe=1" is not there, so check if "hdmi_safe=1" is there
    grep -q "hdmi_safe=1" /boot/config.txt
    if [ $? -eq 0 ]; then  # "hdmi_safe=1" is there, so replace it with "#hdmi_safe=1"
      sudo sed -i '/hdmi_safe=1/c\#hdmi_safe=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # not there, so append the commented statement
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# uncomment if you get no picture on HDMI for a default safe mode" >> /boot/config.txt '
      sudo bash -c 'echo "#hdmi_safe=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi

  #change #sdtv_mode=1/2 or sdtv_mode=1/2 to sdtv_mode=1

  # first check if "#sdtv_mode=1" is in /boot/config.txt
  grep -q "#sdtv_mode=1" /boot/config.txt
  if [ $? -eq 0 ]; then  #  "#sdtv_mode=1" is there, so change it to "sdtv_mode=1"
    sudo sed -i '/#sdtv_mode=1/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#sdtv_mode=1" is not there so check if "#sdtv_mode=2" is there
    grep -q "#sdtv_mode=2" /boot/config.txt
    if [ $? -eq 0 ]; then  #  "#sdtv_mode=2" is there, so change it to "sdtv_mode=1"
      sudo sed -i '/#sdtv_mode=2/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
    else                   # neither "#sdtv_mode=1" nor "#sdtv_mode=2" are there
      grep -q "sdtv_mode=2" /boot/config.txt  # so check if "sdtv_mode=2" is there
      if [ $? -eq 0 ]; then  #  "sdtv_mode=2" is there, so change it to "sdtv_mode=1"
        sudo sed -i '/sdtv_mode=2/c\sdtv_mode=1' /boot/config.txt  >/dev/null 2>/dev/null
      else       # check if "sdtv_mode=1" is there and add it if not
        grep -q "sdtv_mode=1" /boot/config.txt  
        if [ $? -ne 0 ]; then  # "sdtv_mode=1" is not there, so add it at the end (else do nothing)
          sudo bash -c 'echo " " >> /boot/config.txt '
          sudo bash -c 'echo "# uncomment for composite PAL" >> /boot/config.txt '
          sudo bash -c 'echo "sdtv_mode=1" >> /boot/config.txt '
          sudo bash -c 'echo " " >> /boot/config.txt '
        fi
      fi
    fi
  fi

  # change #enable_tvout=1 or enable_tvout=1 to enable_tvout=1 (Add if not present)

  # first check if "#enable_tvout=1" is in /boot/config.txt
  grep -q "#enable_tvout=1" /boot/config.txt
  if [ $? -eq 0 ]; then  # "#enable_tvout=1" is there, so replace it with "enable_tvout=1"
    sudo sed -i '/#enable_tvout=1/c\enable_tvout=1' /boot/config.txt  >/dev/null 2>/dev/null
  else                   # "#enable_tvout=1" is not there, so check for "enable_tvout=1"
    grep -q "enable_tvout=1" /boot/config.txt
    if [ $? -ne 0 ]; then  #  "enable_tvout=1" is not there, so add it at the end (else do nothing)
      sudo bash -c 'echo " " >> /boot/config.txt '
      sudo bash -c 'echo "# Uncomment to enable Comp Vid output" >> /boot/config.txt '
      sudo bash -c 'echo "enable_tvout=1" >> /boot/config.txt '
      sudo bash -c 'echo " " >> /boot/config.txt '
    fi
  fi
}


do_video_change()
{
  menuchoice=$(whiptail --title "Video Output Menu" --menu "Select Choice" 16 78 10 \
    "1 Normal HDMI" "Recommended Mode"  \
    "2 HDMI Safe Mode" "Use for HDMI Troubleshooting" \
    "3 PAL Composite Video" "Use the RPi Video Output Jack" \
    "4 NTSC Composite Video" "Use the RPi Video Output Jack" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) do_Norm_HDMI ;;
        2\ *) do_Safe_HDMI ;;
        3\ *) do_Comp_Vid_PAL ;;
        4\ *) do_Comp_Vid_NTSC ;;
    esac

  menuchoice=$(whiptail --title "Reboot Now?" --menu "Reboot to Apply Changes?" 16 78 10 \
    "1 Yes" "Immediate Reboot"  \
    "2 No" "Apply changes at next Reboot" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
        1\ *) do_Reboot ;;
        2\ *) do_Nothing ;;
    esac
}


do_Shutdown()
{
  sudo shutdown now
}


do_Exit()
{
  exit
}


do_shutdown_menu()
{
  menuchoice=$(whiptail --title "Shutdown Menu" --menu "Select Choice" 16 78 10 \
    "1 Shutdown now" "Immediate Shutdown"  \
    "2 Reboot now" "Immediate reboot" \
    "3 Exit to Linux" "Exit menu to Command Prompt" \
      3>&2 2>&1 1>&3)
    case "$menuchoice" in
      1\ *) do_Shutdown ;;
      2\ *) do_Reboot ;;
      3\ *) do_Exit ;;
    esac
}


do_stop()
{
  sudo killall python3 >/dev/null 2>/dev/null
  
  sleep 0.3
  if pgrep -x "python3" >/dev/null 2>/dev/null
  then
    sudo killall -9 python3 >/dev/null 2>/dev/null
  fi
}


do_receive()
{
  /home/pi/ryde-build/rx.sh &

  # Wait here receiving until user presses a key
  whiptail --title "Receiving" --msgbox "Touch any key to stop receiving" 8 78
  do_stop
}


#********************************************* MAIN MENU *********************************
#************************* Execution of Console Menu starts here *************************

status=0

# Stop the Receiver
do_stop

# Loop round main menu
while [ "$status" -eq 0 ] 
  do
    # Display main menu

    menuchoice=$(whiptail --title "BATC Ryde Receiver Main Menu" --menu "INFO" 18 78 12 \
	"0 Receive" "Start the Ryde Receiver" \
        "1 Stop" "Stop the Ryde Receiver" \
        "2 Start-up" "Set the start-up Preset" \
        "3 Bands" "Set the band details such as LNB Offset" \
        "4 Presets" "Set the details for each preset" \
	"5 Video" "Select the Video Output Mode" \
	"6 Remote" "Select the Remote Control Type" \
	"7 IR Check" "View the IR Codes From a new Remote" \
        "8 Settings" "Advanced Settings" \
	"9 Info" "Display System Info" \
	"10 Update" "Check for Update" \
	"11 Shutdown" "Reboot or Shutdown" \
 	3>&2 2>&1 1>&3)

        case "$menuchoice" in
	    0\ *) do_receive   ;;
            1\ *) do_stop   ;;
            2\ *) do_Set_Defaults ;;
            3\ *) do_Set_Bands ;;
            4\ *) do_Set_Presets ;;
	    5\ *) do_video_change ;;
   	    6\ *) do_Set_RC_Type ;;
   	    7\ *) do_Check_RC_Codes ;;
	    8\ *) do_Settings ;;
            9\ *) do_info ;;
	    10\ *) do_update ;;
	    11\ *) do_shutdown_menu ;;
               *)

        # Display exit message if user jumps out of menu
        whiptail --title "Exiting to Linux Prompt" --msgbox "To return to the menu system, type menu" 8 78

        # Set status to exit
        status=1

        # Sleep while user reads message, then exit
        sleep 1
      exit ;;
    esac
  done
exit