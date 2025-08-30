#!/bin/bash
#Script uses whiptail to create "user friendly" interface
#Simple Rubber Ducky script for raspberry pi

# === File configuration ===
PAYLOAD_DIR="./Payloads" # Payload directory, use .txt files
CZ_LAYOUT="./duckpi_cz.sh" # Custom file, using fixed layout for Windows Czech QWERTZ keyboard
US_LAYOUT="./duckpi.sh"
# ===================================

whiptail --msgbox "Hello!\nThis script requires sudo for using /dev/hidg0." 10 55
if [[ $UID != 0 ]]; then
  whiptail --msgbox "Rerunning script with sudo!" 10 50
  exec sudo "$0" "$@"
fi

while true; do
  if [ ! -d "$PAYLOAD_DIR" ]; then
    whiptail --msgbox "Directory $PAYLOAD_DIR not found!\nCheck it!" 10 50
    break
  fi

  DUCKY_MENU_ITEMS=""
  for file in "$PAYLOAD_DIR"/*.txt; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")
    DUCKY_MENU_ITEMS+=" $filename $filename"
  done

  SELECT_PAYLOAD=$(whiptail --title "Payload selection" --menu "Choose payload to use:" 20 60 10 $DUCKY_MENU_ITEMS 3>&1 1>&2 2>&3)
  if [ -z "$SELECT_PAYLOAD" ]; then
    whiptail --msgbox "No payload file selected.\nEnding script!" 10 50
    break
  fi
  # Ask for keyboard layout
  LAYOUT=$(whiptail --title "Keyboard Layout" --menu "Choose keyboard layout:" 10 30 2 \
    "CZ" "Czech QWERTZ" \
    "US" "United States QWERTY" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && whiptail --msgbox "Going back to payload selection!" 10 50 && continue

  case "$LAYOUT" in
    "CZ") DUCKY_SCRIPT="$CZ_LAYOUT" ;;
    "US") DUCKY_SCRIPT="$US_LAYOUT" ;;
       *) DUCKY_SCRIPT="$CZ_LAYOUT" ;;  # default choice, atleast for me :-))
  esac
  # Simple spinner for wait
  spin='-\|/'
  i=0
  # UDC bind wait
  while true; do
    i=$(((i+1)%4))
    printf "\r${spin:$i:1}"
    sleep .1
    ROLE=$(cat /sys/class/udc/*/state 2>/dev/null)
    if [[ "$ROLE" == "configured" || "$ROLE" == "connected" ]]; then
      break
    fi
  done

  whiptail --yesno "Host detected.\nRun payload $SELECT_PAYLOAD with $LAYOUT layout?" 10 50
  [ $? -ne 0 ] && whiptail --msgbox "Going back to payload selection!" 10 50 && continue

  # PROGRESS BAR SCRIPT - approximate based on delay and lenght, mainly fo visuals like on Flipper Zero
  {
    TOTAL_LINES=$(wc -l < "$PAYLOAD_DIR/$SELECT_PAYLOAD")
    CURRENT=0
    while IFS= read -r line || [ -n "$line" ]; do
      # Handle DELAY command
      if [[ "$line" =~ ^DELAY[[:space:]]+([0-9]+) ]]; then
        delay_ms=${BASH_REMATCH[1]}
        sleep "$(bc <<< "scale=3; $delay_ms/1000")"
      else
        # Send line to ducky interpreter
        echo "$line" > ./duck_line.txt
        "$DUCKY_SCRIPT" ./duck_line.txt >/dev/null 2>&1
      fi
      CURRENT=$((CURRENT+1))
      PERCENT=$((CURRENT*100/TOTAL_LINES))
      echo $PERCENT
    done < "$PAYLOAD_DIR/$SELECT_PAYLOAD"
    rm -f ./duck_line.txt
  } | whiptail --gauge "Running payload $CHOICE ..." 10 30 0
done
