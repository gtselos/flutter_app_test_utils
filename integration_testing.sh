#!/bin/bash

# Script to run flutter integration tests without the need of manually granting permissions
# Doesn't work for ios real devices
# usage: sh integration_testing.sh (ios|android) (device_id)

# to install applesimutils in mac run:
# brew tap wix/brew
# brew install applesimutils


app_dir=~/myApp
app_file_name=app.dart
extra_build_params=(--flavor development --debug)
extra_drive_params=(--flavor development)
package_name_android=com.package.app
package_name_ios=com.package.app
ios_perms="location=always, notifications=YES"
android_perms=android.permission.ACCESS_FINE_LOCATION
device_id=$2



if [[ $1 == "" ]] 
then
    echo "Please specify environment, ios or android"
    exit 1
fi

if [[ $1 != "ios" && $1 != "android" ]] 
then
    echo "Not recognized environment"
    exit 1
fi

if [[ $device_id == "" ]]
then
	if [[ $(flutter devices | grep -c "$1" ) -gt 1 ]]
	then
	    echo "More than one $1 devices connected, please specify device"
	    exit 1
	fi

	device_id=`flutter devices | grep "$1" | cut -d '•' -f2 | xargs`
else
	if [[ $(flutter devices | grep "$1" | grep -e " $device_id " -c ) -eq 0 ]]
	then
	    echo "No $1 device found having id $device_id"
	    exit 1
	fi
fi

echo "Device used: $device_id"

if [[ $1 == "ios" ]]
then
	device_is_emulator=`flutter devices | grep "$device_id" | grep -ce "simulator"`
	if [[ $device_is_emulator -eq 0 ]]
	then
	    echo "Cannot run automatic tests on real ios devices, stopping..."
    	exit 1
	fi
	package="ios"
	extra_build_params+=(--simulator)
else
	package="apk"
fi

echo "getting to app dir..."
cd $app_dir

echo "cleaning, building and installing"

flutter clean && flutter build $package "${extra_build_params[@]}" -t test_driver/$app_file_name && flutter install -d $device_id

if [[ $1 == "ios" ]]
then
	applesimutils --byId $device_id --bundle $package_name_ios --setPermissions "$ios_perms"
else
	adb -s $device_id shell pm grant $package_name_android $android_perms
fi

flutter drive --target=test_driver/$app_file_name "${extra_drive_params[@]}" --no-build -d $device_id


