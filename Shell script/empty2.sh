#adb-push-build-prop.sh

cd .
pwd

sleep 5

ip=127.0.0.1
start_num=$((8500+$1))
echo $start_num
stop_num=$((8500+$2))
echo $stop_num

/usr/bin/adb devices
for port in $(seq ${start_num} ${stop_num})
do
{
        #adb connect ${ip}:${port}
        #sleep 3
        #adb -s ${ip}:${port} root
        #sleep 3
        #adb connect ${ip}:${port}
        #sleep 3
        adb -s ${ip}:${port} push ./build.prop /vendor
        sleep 2
}

done


