#########################################################################
# File Name: gpu_monitor.sh
# Author: didicout
# mail: i@julin.me
# Created Time: Fri 03 Jun 2016 05:45:09 PM CST
#########################################################################
#!/bin/bash
readonly items="utilization.gpu,utilization.memory,memory.total,memory.free,memory.used"
readonly item_count=$(echo $items | tr "," "\n" | wc -l)
readonly gpu_ids=$(nvidia-smi -L | awk '{print $2}' | tr -d ":")

for gpu in $gpu_ids
do
    result=$(nvidia-smi -i $gpu --query-gpu=$items --format=csv,noheader,nounits)

    for i in $(seq $item_count)
    do
        item=$(echo $items | cut -d "," -f $i | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        value=$(echo $result | cut -d "," -f $i | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        echo "gpu$gpu.$item:$value"
    done
done

