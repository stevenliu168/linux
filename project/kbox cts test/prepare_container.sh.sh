#prepare_container.sh

#cd /home/lxn/CTS
#CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#cd ${CURRENT_DIR}
cd .
pwd

./android11_kbox.sh delete $1 $2
./android11_kbox.sh start kbox:0818r48 $1 $2

sleep 5

ip=127.0.0.1
start_num=$((8500+$1))
echo $start_num
stop_num=$((8500+$2))
echo $stop_num

cd /home/lxn/CTS/android-cts-media-1.5
/usr/bin/adb devices
for port in $(seq ${start_num} ${stop_num})
do
{
        adb connect ${ip}:${port}
        sleep 3
        adb -s ${ip}:${port} root
        sleep 3
        adb connect ${ip}:${port}
        sleep 3
	adb -s ${ip}:${port} shell input touchscreen swipe 581 756 581 756
	sleep 2
        adb -s ${ip}:${port} shell am start -n com.android.settings/.Settings
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 343 1147 305 292
        sleep 2
	
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 2
       # adb -s ${ip}:${port} shell input touchscreen swipe 338 227 338 227+
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 343 1147 305 292
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input touchscreen swipe 352 1127 352 1127
        sleep 1
        adb -s ${ip}:${port} shell input keyevent 4
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 341 969 341 969
        sleep 2

        adb -s ${ip}:${port} shell input touchscreen swipe 334 233 334 233
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 349 236 349 236
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 343 485 343 485
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 666 102 666 102
        sleep 2
        adb -s ${ip}:${port} shell input keyboard text "english"
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 349 236 349 236
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 356 1054 356 1054
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 666 102 666 102
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 666 102 666 102
        sleep 2
        adb -s ${ip}:${port} shell input touchscreen swipe 349 236 349 236
        sleep 2
	adb -s ${ip}:${port} shell input touchscreen swipe 575 100 575 100
	sleep 2
	adb -s ${ip}:${port} shell input touchscreen swipe 584 712 584 712
	sleep 2
        adb -s ${ip}:${port} shell input keyevent 3
        sleep 2

        ./copy_media.sh all -s ${ip}:$port
}

done

