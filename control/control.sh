#!/bin/bash
#
# Author: didicout <i@julin.me>
# Brief:
#   Control script for starting, checking and stopping a program.
#

############### Configuration ################

# Workspace path (relative to this script)
readonly WORK_PATH='..'

# Name (pattern in full command line) for checking and killing the proc
readonly PROC_NAME='test-control'

# 0: Only one proc. Check by name when starting. Kill by name.
# 1: Allow multi processes. Check by pid and name when starting. Kill by pid and name.
# Different processes must be started in different dirs.
readonly ALLOW_MULTI_PROC=0

# will be run in workspace
readonly START_COMMAND='./test-control'

# grep
readonly GREP='fgrep'

# grep -v when checking the proc
readonly GREP_V='vi\|vim\|tail\|tailf\|less\|more'

# sleep
readonly SLEEP='sleep'

# when starting
set_env() {
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
}

############ End of configuration ############


#######################################
# Brief:
#   Check whether the proc is running by its name.
# Globals:
#   PROC_NAME
#   GREP
#   GREP_V
# Arguments:
#   None
# Returns:
#   0: running
#   other: not running
#######################################
check_by_name() {
    ps -fj ax | ${GREP} "${PROC_NAME}"| ${GREP} -v "${GREP}" | ${GREP} -v "${GREP_V}" >/dev/null 2>&1
}

#######################################
# Brief:
#   Check whether the proc is running by its pid and name.
# Globals:
#   PIDFILE
# Arguments:
#   None
# Returns:
#   0: running
#   other: not running
#######################################
check_by_id_name() {
    check_by_name && ps -p "$(cat ${PIDFILE} 2>/dev/null)" >/dev/null 2>&1
}

#######################################
# Brief:
#   Check whether the proc is running.
# Globals:
#   ALLOW_MULTI_PROC
# Arguments:
#   None
# Returns:
#   0: running
#   other: not running
#######################################
check_proc() {
    if [[ "${ALLOW_MULTI_PROC}" -eq 0 ]]; then
        check_by_name
    else
        check_by_id_name
    fi
}

show_help() {
    echo "$0 <start|stop|restart|status>"
    exit 1
}

die() {
    echo -e "\033[91m[FAILED]\033[0m $1"
    exit 1
}

ok() {
    echo -e "\033[92m[OK]\033[0m $1"
}

#######################################
# Brief:
#   Send a signal to the proc.
# Globals:
#   ALLOW_MULTI_PROC
#   PIDFILE
#   GREP
#   GREP_V
#   PROC_NAME
# Arguments:
#   $1: signum
#######################################
send_kill() {
    local signum="$1"
    local check_id
    if [[ "${ALLOW_MULTI_PROC}" -ne 0 ]]; then
        check_id="-p $(cat ${PIDFILE} 2>/dev/null)"
    else
        check_id="ax"
    fi
    ps -fj ${check_id} | ${GREP} ${PROC_NAME} | ${GREP} -v "${GREP}" | ${GREP} -v "${GREP_V}" | awk "{print \"kill -s ${signum} \" \$2}" | sh
}

start() {
    check_proc
    if [ $? -eq 0 ]; then
        ok "start"
        return 0
    fi

    set_env
    mkdir -p runtime

    nohup ${START_COMMAND} 1>/dev/null 2>&1 &
    local pid=$!
    echo "${pid}" > ${PIDFILE}

    for i in $(seq 10); do
        ${SLEEP} 1

        check_proc
        if [ $? -eq 0 ]; then
            ok "start"
            return 0
        fi
    done

    die "start"
}

stop() {
    check_proc
    if [ $? -ne 0 ]; then
        ok "stop"
        return 0
    fi

    for i in $(seq 5); do
        send_kill 15
        ${SLEEP} 1
        check_proc
        if [ $? -ne 0 ]; then
            ok "stop"
            return 0
        fi
    done
    for i in 1 2 3; do
        send_kill 9
        ${SLEEP} 1
        check_proc
        if [ $? -ne 0 ]; then
            ok "stop"
            return 0
        fi
    done
    die "stop"
}

restart() {
    stop
    start
    return 0
}

status() {
    check_proc
    if [ $? -eq 0 ]; then
        echo 'Running'
        return 0
    else
        echo 'Not running'
        return 1
    fi
}

#######################################
# Globals:
#   WORKSPACE
#   PIDFILE
# Arguments:
#   $1: start/stop/restart/status/help
#######################################
main() {
    case "$1" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        *)
            show_help
            ;;
    esac
}

cd "$(dirname $0)/${WORK_PATH}" || exit 1
readonly WORKSPACE=$(pwd)
readonly PIDFILE="${WORKSPACE}/runtime/pid"

main "$@"

