#android11_kbox.sh
#!/bin/bash

#===============================================================================
# Functions
#===============================================================================
function check_environment() {
    # root权限执行此脚本
    if [ "${UID}" -ne 0 ]; then
        echo  "请使用root权限执行"
        exit 1
    fi

    # 支持非当前目录执行
    CURRENT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    echo "Current Path:$CURRENT_DIR"
    cd ${CURRENT_DIR}

    # 检查是否存在配置文件，不存在配置文件，直接退出
    local KBOX_CFG=$CURRENT_DIR/kbox_config.cfg
    if [ -f $KBOX_CFG ]
    then
        source $KBOX_CFG
        echo "kbox_config.cfg exists, loaded"
    else
        echo "kbox_config.cfg not found"
        exit 1
    fi

    check_ashmem_binder

    # 如果是需要转码的机型，在使用脚本过程中检查转码
    local VENDOR_ID=$(lscpu | grep "Vendor ID:" | awk '{print $3}')
    if [ $VENDOR_ID == "0x48" ]; then
        check_exagear
    fi
}

function check_ashmem_binder() {
    # 已经加载无需恢复
    if [ ! -z $(lsmod | grep "aosp_binder_linux" | awk '{print $1}') ] && 
       [ ! -z $(lsmod | grep "ashmem_linux" | awk '{print $1}') ]; then
        return
    fi

    # 确定kernel版本
    local KERNEL_VERSION=$(uname -r)

    # 检查aosp_binder_linux并安装
    if [ -z $(lsmod | grep "aosp_binder_linux" | awk '{print $1}') ]; then
        if [ -e "/lib/modules/${KERNEL_VERSION}/kernel/lib/aosp_binder_linux.ko" ]; then
            insmod /lib/modules/${KERNEL_VERSION}/kernel/lib/aosp_binder_linux.ko num_devices=400
        else
            echo "can not find aosp_binder_linux.ko"
            exit 1
        fi
    fi

    # 检查ashmem_linux并安装
    if [ -z $(lsmod | grep "ashmem_linux" | awk '{print $1}') ]; then
        if [ -e "/lib/modules/${KERNEL_VERSION}/kernel/lib/ashmem_linux.ko" ]; then
            insmod /lib/modules/${KERNEL_VERSION}/kernel/lib/ashmem_linux.ko
        else
            echo "can not find ashmem_linux.ko"
            exit 1
        fi
    fi
        
    chmod 600 /dev/aosp_binder*
    chmod 600 /dev/ashmem 
    chmod 600 /dev/dri/* 
    chmod 600 /dev/input
}

function check_exagear() {
    # 已经注册，无需恢复
    if [ -e "/proc/sys/fs/binfmt_misc/ubt_a32a64" ]; then
        return
    fi

    # 在归档路径下模糊查找
    local UBT_PATHS=($(ls /root/dependency/*/ubt_a32a64))
    if [ ${#UBT_PATHS[@]} -ne 1 ]; then
        echo "No ubt_a32a64 file or many ubt_a32a64 files exist!"
        exit 1
    fi

    # 恢复exgear文件
    mkdir -p /opt/exagear
    chmod -R 700 /opt/exagear
    cp -rf ${UBT_PATHS[0]} /opt/exagear/
    cd /opt/exagear
    chmod +x ubt_a32a64

    # 注册转码 续行符后字符串顶格
    echo ":ubt_a32a64:M::\x7fELF\x01\x01\x01\x00\x00\x00\x0"\
"0\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xf"\
"f\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x00\xfe\xff\xff\xff:/opt/exagear/ubt_a32a64:POCF" > /proc/sys/fs/binfmt_misc/register
}

function check_paras() {
    set +e
    
    if [ $# -eq 0 ]; then
        echo "command must be \"start\", \"delete\" or \"restart\" "
        exit 1
    fi

    if [ $1 == "start" ]; then
        if [ $# -gt 4 ]; then
            echo "the number of parameters exceeds 4!"
            echo "Usage: "
            echo "./android11_kbox.sh start <image_id> <start_container_id> <end_container_id>"
            echo "./android11_kbox.sh start <image_id> <container_id>"
            exit 1;
        fi

        local IMAGE_ID=$2
        if [[ "${IMAGE_ID}" =~ ":" ]]; then
            local IMAGE_RE=$(echo ${IMAGE_ID} | cut -d ':' -f1)
            tag=$(echo ${IMAGE_ID} | cut -d ':' -f2)
            docker images | awk '{print $1" "$2}' | grep -w "${IMAGE_RE}" | grep -w "${tag}" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "no image ${IMAGE_ID}"
                exit 1
            fi
        else
            docker images | awk '{print $3}' | grep -w "${IMAGE_ID}" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "no image ${IMAGE_ID}"
                exit 1
            fi
        fi

        if [ -n "`echo "$3$4" | sed 's/[0-9]//g'`" ]; then
            echo "The third and fourth parameters must be numbers."
            exit 1
        fi

        local MIN=$3 MAX=$4
        if [ -z "$4" ]; then
            MAX=$3
        fi

        if [ $MIN -gt $MAX ]; then
            echo "start_num must be less than or equal to end_num"
            exit 1
        fi
    elif [ $1 == "delete" ]; then
        if [ $# -gt 3 ]; then
            echo "the number of parameters exceeds 3!"
            echo "Usage: "
            echo "./android11_kbox.sh delete <start_container_id> <end_container_id>"
            echo "./android11_kbox.sh delete <container_id>"
            exit 1
        fi

        if [ -n "`echo "$2$3" | sed 's/[0-9]//g'`" ]; then
            echo "The second and third parameters must be numbers."
            exit 1
        fi

        local MIN=$2 MAX=$3
        if [ -z $3 ]; then
            MAX=$2
        fi

        if [ $MIN -gt $MAX ]; then
            echo "start_num must be less than or equal to end_num"
            exit 1
        fi
    elif [ $1 == "restart" ]; then
        if [ $# -gt 3 ]; then
            echo "the number of parameters exceeds 3!"
            echo "Usage: "
            echo "./android11_kbox.sh restart <start_container_id> <end_container_id>"
            echo "./android11_kbox.sh restart <container_id>"
            exit 1
        fi

        if [ -n "`echo "$2$3" | sed 's/[0-9]//g'`" ]; then
            echo "The second and third paramelters must be numbers."
            exit 1
        fi

        local MIN=$2 MAX=$3
        if [ -z $3 ]; then
            MAX=$2
        fi

        if [ $MIN -gt $MAX ]; then
            echo "start_num must be less than or equal to end_num"
            exit 1
        fi
    else
        echo "command must be \"start\", \"delete\" or \"restart\" "
    fi
}

function get_closest_numas() {
    local NUM_OF_NUMA=$(lscpu | grep "NUMA node(s)" | awk '{print $3}')

    local CPU_LIST_ARRAY=
    for ((NUMA=0; NUMA<${NUM_OF_NUMA}; NUMA++))
    do
        CPU_LIST_ARRAY[$NUMA]=$(cat /sys/devices/system/node/node${NUMA}/cpulist |sed "s/-/ /")
    done

    local CPU_LIST=
    for CPU in $@
    do
        for ((NUMA=0; NUMA<${NUM_OF_NUMA}; NUMA++))
        do
            # 将带空格的文本转换成array，其中第一个元素是最小值，第二个元素是最大值
            CPU_LIST=(${CPU_LIST_ARRAY[$NUMA]})
            if (( ${CPU} >= ${CPU_LIST[0]} )) && (( ${CPU} <= ${CPU_LIST[1]} ))
            then
                echo $NUMA
            fi
        done
    done
}

function wait_container_ready() {
    local KBOX_NAME=$1
    docker exec -itd ${KBOX_NAME} /kbox-init.sh
    local starttime=$(date +'%Y-%m-%d %H:%M:%S')
    local start_seconds=$(date --date="${starttime}" +%s)
    if [ $? -eq 0 ]; then
        count_time=0
        set +e
        while true; do
            docker exec -i ${KBOX_NAME} getprop sys.boot_completed | grep 1 >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "${KBOX_NAME} started successfully at $(date +'%Y-%m-%d %H:%M:%S')!"
                if [ -f "apk_init.sh" ]; then
                    sed -i "s/\r//" apk_init.sh
                    docker cp apk_init.sh ${KBOX_NAME}:/
                fi
                break
            fi
            # 200秒未成功启动超时跳过
            if [ ${count_time} -gt 50 ]; then
                echo -e "\033[1;31mStart check timed out,${KBOX_NAME} unable to start\033[0m"
                echo -e "\033[1;31m${KBOX_NAME} started failed\033[0m"
                break
            fi
            sleep 4
            count_time=$((count_time + 1))
        done
        set -e
    else
        error "${KBOX_NAME} started failed"
    fi
    local endtime=$(date +'%Y-%m-%d %H:%M:%S')
    local end_seconds=$(date --date="${endtime}" +%s)
    echo "time: "$((end_seconds - start_seconds))"s"
    echo -e "---------------------- done ----------------------\n"
}

function disable_ipv6_icmp() {
    # 更改容器内部accept_redirects参数配置，禁止ipv6的icmp重定向功能
    KBOX_NAME=$1
    temp=$(mktemp)
    echo 0 > $temp
    pid=$(docker inspect ${KBOX_NAME} | grep Pid | awk -F, '{print $1}' | sed -n '1p' | awk '{print $2}')
    nsenter -n -t ${pid} cp $temp /proc/sys/net/ipv6/conf/all/accept_redirects
    rm $temp
}

function start_box_by_id() {

    # 镜像名
    local IMAGE_NAME=$2

    # 容器编号
    local TAG_NUMBER=$3

    # 没有GPU不启动容器
    local GPUS_INFO=($(lspci -D | grep "VGA compatible controller: Advanced Micro Devices" | awk '{print $1}'))
    if [ ${#GPUS_INFO[@]} -eq 0 ]; then
        echo "No GPU exists on the host"
        exit 1
    fi

    # 容器名
    local CONTAINER_NAME="kbox_$TAG_NUMBER"

    # 存储大小
    local STORAGE_SIZE_GB=16

    # 运行内存
    local RAM_SIZE_MB
    if [ -n "$(lspci -D | grep "VGA compatible controller: Advanced Micro Devices" | grep "73a3")" ]; then
        RAM_SIZE_MB=6144
    else
        RAM_SIZE_MB=4096
    fi

    # CPUS
    local CPUS
    local CPUS_STRING=${KBOX_CPUSET_MAP[TAG_NUMBER - 1]}
    IFS=' ' read -r -a CPUS <<< $CPUS_STRING

    # GPU
    local GPUS_RENDER=${KBOX_GPU_MAP[TAG_NUMBER - 1]}

    # Data mount dir
    local MOUNT_DIR=${KBOX_MOUNT_MAP[TAG_NUMBER - 1]}

    # NUMA
    local NUMAS=($(echo $(get_closest_numas ${CPUS[@]}) | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # Binder
    local BINDER_NODES=("/dev/aosp_binder$TAG_NUMBER" \
                        "/dev/aosp_binder$(($TAG_NUMBER + 120))" \
                        "/dev/aosp_binder$(($TAG_NUMBER + 240))")

    # 调试端口
    local PORTS=("$((8500+$TAG_NUMBER)):5555")

    # docker额外启动参数
    local EXTRA_RUN_OPTION=""

    bash $CURRENT_DIR/base_box.sh start \
    --name "$CONTAINER_NAME" \
    --cpus "${CPUS[*]}" \
    --numas "${NUMAS[*]}" \
    --gpus  "${GPUS_RENDER[*]}" \
    --storage_size_gb "$STORAGE_SIZE_GB" \
    --ram_size_mb "$RAM_SIZE_MB" \
    --binder_nodes "${BINDER_NODES[*]}" \
    --ports "${PORTS[*]}" \
    --extra_run_option "$EXTRA_RUN_OPTION" \
    --image "$IMAGE_NAME" \
    --user_data_path "$MOUNT_DIR" \
    --docker_data_path "/var/lib/docker"


    # 调整vinput设备权限
    cid=$(docker ps | grep -w ${CONTAINER_NAME} | awk '{print $1}')
    echo "c 13:* rwm" >$(ls -d /sys/fs/cgroup/devices/docker/$cid*/devices.allow)

    if [ -n "$(docker ps -a --format {{.Names}} | grep "$CONTAINER_NAME$")" ]; then
        # 等待容器启动
        wait_container_ready ${CONTAINER_NAME}

        # 更改容器内部accept_redirects参数配置，禁止ipv6的icmp重定向功能
        disable_ipv6_icmp ${CONTAINER_NAME}
    fi
}

function main() {
    if [ ! -e "$CURRENT_DIR/base_box.sh" ]; then
        echo "Can not find file base_box.sh"
        exit 1
    fi

    if [ $1 = "start" ];then
        local MIN=$3 MAX=$4
        if [ -z $4 ]; then
            MAX=$3
        fi

        local TAG_NUMBER
        for TAG_NUMBER in $(seq $MIN $MAX); do
            if [ -n "$(docker ps -a --format {{.Names}} | grep "kbox_$TAG_NUMBER$")" ]; then
                echo "kbox_$TAG_NUMBER exist!"
            else
                start_box_by_id $1 $2 $TAG_NUMBER
            fi
        done
    elif [ $1 = "delete" ]; then
        local MIN=$2 MAX=$3
        if [ -z $3 ]; then
            MAX=$2
        fi

        local TAG_NUMBER
        for TAG_NUMBER in $(seq $MIN $MAX);do
            if [ -z "$(docker ps -a --format {{.Names}} | grep "kbox_$TAG_NUMBER$")" ]; then
                echo "no container kbox_$TAG_NUMBER!"
            else
                local MOUNT_DIR=${KBOX_MOUNT_MAP[TAG_NUMBER - 1]}
                bash $CURRENT_DIR/base_box.sh delete "kbox_$TAG_NUMBER" "$MOUNT_DIR"
            fi
        done
    elif [ $1 = "restart" ]; then
        local MIN=$2 MAX=$3
        if [ -z $3 ]; then
            MAX=$2
        fi
        local TAG_NUMBER
        for TAG_NUMBER in $(seq $MIN $MAX);do
            if [ -z "$(docker ps -a --format {{.Names}} | grep "kbox_$TAG_NUMBER$")" ]; then
                echo "no container kbox_$TAG_NUMBER!"
            else
                local MOUNT_DIR=${KBOX_MOUNT_MAP[TAG_NUMBER - 1]}
                bash $CURRENT_DIR/base_box.sh restart "kbox_$TAG_NUMBER" "$MOUNT_DIR"
                # 调整vinput设备权限
                cid=$(docker ps | grep -w "kbox_$TAG_NUMBER" | awk '{print $1}')
                echo "c 13:* rwm" >$(ls -d /sys/fs/cgroup/devices/docker/$cid*/devices.allow)
            fi
        done
    fi
}

check_environment
check_paras $@
main "$@"
