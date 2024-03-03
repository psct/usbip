#!/bin/bash

# Enancement for https://github.com/psct/usbip
# This utility expects the systemd dynamic unit files
# provided at https://github.com/psct/usbip
#
# Issue/Problem to solve:
# When the usbipd server is rebooted;
# When the USB device at usbipd server is removed (and re-inserted)
# The binding by uspip client with the server USB device gets disconnected
# The binding does not auto recover
#
# This utility will ONLY restore the binding for
# dynamic unit files which have been started
# Unit files which have not been enabled/started, will be ignored
#
# dynamic unit file example:
#   usbip@pi4:0403:6001.service
#
# USAGE:
#  Call this script on a regular basis, eg from a cron.d job (every minute)
#  /etc/cron.d/uspib_monitor:
#  PATH=/bin:/usr/bin:/sbin:/usr/sbin !!IMPORTANT, add in cron.d file!!
#  * * * * * root /<path to script>/usbip_systemd_monitor

scriptname=`basename "$0"`
logger -t ${scriptname} "START ${scriptname[$BASHPID]} PID = $BASHPID"

# Find all dynamic unit files with pattern like
# usbip@usbipdserver:2341:8036.service
# and store in serviceArray
# Ignore duplicates
# systemctl --no-pager --type=service --state=failed | grep usbip@
# systemctl --no-pager --type=service --state=active | grep usbip@

# counter for array
arrayindex=0

# Store retrieved info on unit files in 3 different arrays:
# 1. servicesArray: Full name of dynamic unit file, e.g. "usbip@pi4:0403:6001.service"
# 2. deviceID: USB device id, e.g. "0403:6001"
# 3. usbipdServer, e.g. "pi4"


# Query usbip@ unit files, based on state failed, active and exited
systemctlOutput=$(systemctl --no-pager --type=service --state=failed | grep usbip@)
for str in ${systemctlOutput[@]}; do

  # With regex and BASH_REMATCH, find dynamic unit filename, deviceID and usbipdServer
  if [[ "${str}" =~ ^usbip@(.*):(.*:.*)\.service$ ]]; then

    # Already store deviceID and usbipdServer, as
    # BASH_REMATCH will lose content after duplicate check
    # In case it is a duplicate, results are omitted
    # As servicesArray is leading
    deviceID[${arrayindex}]=${BASH_REMATCH[2]}
    usbipdServer[${arrayindex}]=${BASH_REMATCH[1]}

    # Check if unit file is already in array; if so, skip
    if [[ "${servicesArray[*]}" =~ "${str}" ]]; then
      continue
    fi

    servicesArray[${arrayindex}]=${str}
    (( arrayindex++ ))
  fi
done

systemctlOutput=$(systemctl --no-pager --type=service --state=active | grep usbip@)
for str in ${systemctlOutput[@]}; do
  if [[ "${str}" =~ ^usbip@(.*):(.*:.*)\.service$ ]]; then

    # Already store deviceID and usbipdServer, as
    # BASH_REMATCH will lose content after duplicate check
    # In case it is a duplicate, results are omitted
    # As servicesArray is leading
    deviceID[${arrayindex}]=${BASH_REMATCH[2]}
    usbipdServer[${arrayindex}]=${BASH_REMATCH[1]}

    # Check if unit file is already in array; if so, skip
    if [[ "${servicesArray[*]}" =~ "${str}" ]]; then
      continue
    fi

    servicesArray[${arrayindex}]=${str}
    (( arrayindex++ ))
  fi
done

systemctlOutput=$(systemctl --no-pager --type=service --state=exited | grep usbip@)
for str in ${systemctlOutput[@]}; do
  if [[ "${str}" =~ ^usbip@(.*):(.*:.*)\.service$ ]]; then

    # Already store deviceID and usbipdServer, as
    # BASH_REMATCH will lose content after duplicate check
    # In case it is a duplicate, results are omitted
    # As servicesArray is leading
    deviceID[${arrayindex}]=${BASH_REMATCH[2]}
    usbipdServer[${arrayindex}]=${BASH_REMATCH[1]}

    # Check if unit file is already in array; if so, skip
    if [[ "${servicesArray[*]}" =~ "${str}" ]]; then
      continue
    fi

    servicesArray[${arrayindex}]=${str}
    (( arrayindex++ ))
  fi
done

arrayLength=${#servicesArray[@]}

# print dynamic unit files found
for (( i=0; i<${arrayLength}; i++ )); do
  logger -t ${scriptname} "Found dynamic unitfile: ${servicesArray[${i}]}; deviceID: ${deviceID[${i}]}; server: ${usbipdServer[${i}]}"
done

# Actual checking if unit file is active and usb available for binding
for (( i=0; i<${arrayLength}; i++ )); do
  logger -t ${scriptname} "Check unit file: ${servicesArray[${i}]}........"

  # Check if unit file is active (if not, we will skip)
  systemctl is-active --quiet ${servicesArray[${i}]}

  if [ "$?" -eq "0" ]; then
    logger -t ${scriptname} "${servicesArray[${i}]} STARTED";

    # Check if USB device is available for binding
    # This means that server is back; or USB has been re-inserted
    deviceavailable=$(usbip list -r ${usbipdServer[${i}]} | grep "${deviceID[${i}]}" | wc -l)
    logger -t ${scriptname} "deviceavailable: ${deviceavailable}"

    if [ "${deviceavailable}" -eq "1" ]; then
      logger -t ${scriptname} "Remote USB device available for binding....restart unit file ${servicesArray[${i}]}"
      systemctl restart ${servicesArray[${i}]}
    else
      logger -t ${scriptname} "No remote USB device available for binding OR device is already binded"
    fi

  else
    logger -t ${scriptname} "${servicesArray[${i}]} STOPPED";
    logger -t ${scriptname} "No further checking..."
  fi

done

logger -t ${scriptname} "EXIT ${scriptname[$BASHPID]} PID = $BASHPID"
exit 0;
