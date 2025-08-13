#!/bin/bash

LAT=     #Your latitude
LONG=    # Your longitude
METHOD=4 # Calculation method (not an expert in this, make sure to do your own research if you wanna modify this, gemini pro said this was fine)

# Function to get prayer times and calculate next prayer
get_next_prayer() {
  DATE=$(date +%Y-%m-%d)
  OUTPUT=$(curl -s "http://api.aladhan.com/v1/timings/$DATE?latitude=$LAT&longitude=$LONG&method=$METHOD")

  # Get current time in seconds since midnight
  current_seconds=$(date +%s)

  # Extract prayer times
  fajr=$(echo "$OUTPUT" | jq -r '.data.timings.Fajr')
  sunrise=$(echo "$OUTPUT" | jq -r '.data.timings.Sunrise')
  dhuhr=$(echo "$OUTPUT" | jq -r '.data.timings.Dhuhr')
  asr=$(echo "$OUTPUT" | jq -r '.data.timings.Asr')
  maghrib=$(echo "$OUTPUT" | jq -r '.data.timings.Maghrib')
  isha=$(echo "$OUTPUT" | jq -r '.data.timings.Isha')

  # Get today's date for time conversion
  today=$(date +%Y-%m-%d)

  # Convert prayer times to seconds since midnight
  fajr_sec=$(date -d "$today $fajr" +%s)
  sunrise_sec=$(date -d "$today $sunrise" +%s)
  dhuhr_sec=$(date -d "$today $dhuhr" +%s)
  asr_sec=$(date -d "$today $asr" +%s)
  maghrib_sec=$(date -d "$today $maghrib" +%s)
  isha_sec=$(date -d "$today $isha" +%s)

  # Check which is the next prayer
  if [ $current_seconds -lt $fajr_sec ]; then
    next_prayer="Fajr"
    next_time="$fajr"
    next_seconds=$fajr_sec
  elif [ $current_seconds -lt $sunrise_sec ]; then
    next_prayer="Sunrise"
    next_time="$sunrise"
    next_seconds=$sunrise_sec
  elif [ $current_seconds -lt $dhuhr_sec ]; then
    next_prayer="Dhuhr"
    next_time="$dhuhr"
    next_seconds=$dhuhr_sec
  elif [ $current_seconds -lt $asr_sec ]; then
    next_prayer="Asr"
    next_time="$asr"
    next_seconds=$asr_sec
  elif [ $current_seconds -lt $maghrib_sec ]; then
    next_prayer="Maghrib"
    next_time="$maghrib"
    next_seconds=$maghrib_sec
  elif [ $current_seconds -lt $isha_sec ]; then
    next_prayer="Isha"
    next_time="$isha"
    next_seconds=$isha_sec
  else
    # If after Isha, next is tomorrow's Fajr
    TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
    TOMORROW_OUTPUT=$(curl -s "http://api.aladhan.com/v1/timings/$TOMORROW?latitude=$LAT&longitude=$LONG&method=$METHOD")
    next_prayer="Fajr"
    next_time=$(echo "$TOMORROW_OUTPUT" | jq -r '.data.timings.Fajr')
    next_seconds=$(date -d "$TOMORROW $next_time" +%s)
  fi

  # Calculate time difference
  diff_seconds=$((next_seconds - current_seconds))
  hours=$((diff_seconds / 3600))
  minutes=$(((diff_seconds % 3600) / 60))

  # Return values
  echo "$next_prayer|$next_time|$hours hours $minutes minutes"
}

# Function to display large text using figlet
display_large_text() {
  local text="$1"
  # Check if figlet is installed
  if command -v figlet >/dev/null 2>&1; then
    figlet -f big "$text"
  else
    # Fallback if figlet is not available
    echo "$text"
  fi
}

# Main execution
result=$(get_next_prayer)
next_prayer=$(echo "$result" | cut -d'|' -f1)
next_time=$(echo "$result" | cut -d'|' -f2)
time_diff=$(echo "$result" | cut -d'|' -f3)

# Clear screen
clear

# Display with colors
echo -e "\033[1;36m$(display_large_text "Next Prayer")\033[0m"
echo
echo -e "\033[1;32mPrayer:\033[0m \033[1;37m$next_prayer\033[0m"
echo -e "\033[1;32mTime:\033[0m \033[1;37m$next_time\033[0m"
echo
echo -e "\033[1;33mTime Until:\033[0m"
display_large_text "$time_diff"
echo

# Optional: Add a visual indicator
echo -e "\033[1;35m$(printf '=%.0s' {1..50})\033[0m"
echo

# Wait for user input to exit
echo -e "\033[1;37mPress any key to exit...\033[0m"
read -n1 -s key
echo
echo "Exiting..."
