#!/bin/bash 

#  Status: Complete/Done (mostly)
# Purpose: Script to wake up my NUCs
#    Note: This is a total hack and is ripe for a TON of issues in any sort of "uncontrolled environment"
#          But, will work awesome in my lab ;-)

SLEEPYTIME=10

HARDWARE_INVENTORY=../Files/hardware.csv
[ ! -f $HARDWARE_INVENTORY ] && { echo "ERROR: Hardware Inventory is not found."; exit 9; }

PRIMARY_INTERFACE=$(route | grep '^default' | grep -o '[^ ]*$')

# Figure out which column the MAC address is in the hardware inventory
# This is needed as I have seen "hardware.csv" with different numbers of columns.  Some with the bmc info, others without
# Note: index by 1 as the array column count starts with 0

# First, save the IFS value (as we are about to modify it - and we will want to return it later)
unset saved_IFS
[ -n "${IFS+set}" ] && saved_IFS=$IFS

# Set the IFS to a comma - then set "DELIM_IFS" to the same value to use as a delimiter later
IFS=','
DELIM_IFS=$IFS
while read -a line
do
  for COLUMN in "${!line[@]}"; do
        #echo "${line[COLUMN]}"
        if [ "${line[COLUMN]}" == "mac" ]; then MAC_COLUMN=$((COLUMN + 1)); fi
  done
done < $HARDWARE_INVENTORY
# Return the IFS value to orignal
IFS=$saved_IFS

for MAC in `cat $HARDWARE_INVENTORY | cut -f${MAC_COLUMN} -d"${DELIM_IFS}"` 
do 
  echo "sudo etherwake -i $PRIMARY_INTERFACE $MAC"
  #etherwake $MAC
  secs=$(($SLEEPYTIME))
while [ $secs -gt 0 ]; do
   echo -ne "pause for: $secs\033[0K\r"
   sleep 1 # Countdown in 1 second intervals 
   : $((secs--))
done 
done

exit 0

# This is the example I started with
example() {
IFS=','
read -a headers
while read -a line; 
do
    for i in "${!line[@]}"; do
        echo "${headers[i]}: ${line[i]}"
    done < $HARDWARE_INVENTORY
done 
}

