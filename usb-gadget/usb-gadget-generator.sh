#!/bin/bash -e

declare -r GENERATOR_NAME=${0/*\//}
declare -r BIN_PREFIX=/usr/bin/
declare -r SERVICE_NAME=usb-gadget@.service
declare -r SERIAL_GETTY_SERVICE_NAME=serial-getty@ttyGS0.service
declare -r DROP_IN_FNAME=default-instance.conf
declare -r SYS_UDC_DIR=/sys/class/udc

declare -r DST_DIR=$1
if [ -z "${DST_DIR}" ]; then
    exit 1
fi

get_unit_preamble() {
cat <<EOF
#
# This drop-in was generated by ${GENERATOR_NAME}.
# Please do not edit this file.
#
[Unit]
EOF
}

declare -a UDCS
UDCS=($(${BIN_PREFIX}find ${SYS_UDC_DIR} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")) || true

for udc in ${UDCS[*]}; do
    udc_esc=$(${BIN_PREFIX}systemd-escape --template=${SERVICE_NAME} ${udc})
    ${BIN_PREFIX}mkdir -p ${DST_DIR}/${SERVICE_NAME}.d
    ${BIN_PREFIX}mkdir -p ${DST_DIR}/${SERIAL_GETTY_SERVICE_NAME}.d
    (
        get_unit_preamble
        cat <<EOF
Description=USB Gadget - %I

[Install]
DefaultInstance=${udc}
EOF
    ) > ${DST_DIR}/${SERVICE_NAME}.d/${DROP_IN_FNAME}
    (
        get_unit_preamble
        cat <<EOF
PartOf=${udc_esc}
EOF
    ) > ${DST_DIR}/${SERIAL_GETTY_SERVICE_NAME}.d/part-of.conf
    break
done
