#!/bin/bash

TEMP_DIR_NAME="m3u8converter-temp"
M3U8_FILE_NAME="play.m3u8"
LIST_FILE_NAME="list.txt"
WGET_LOG_NAME="wget.log"
WGET_USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.3996.0 Safari/537.36"
FFMPEG_LOG_NAME="ffmpeg.log"
FFMPEG_ERR_LOG_NAME="ffmpeg-err.log"
OUT_VID_NAME="out.mp4"

m3u8c_show_usage() {
    echo "usage: $0 -i <m3u8 file> -b <base url> [-d <drm file>] [-f] [-m listing|download|convert]"
}

m3u8c_urllisting() {
    cmds=$(cat "${M3U8_FILE_NAME}" | tr -d '\r' | tr -d '\n' | tr '#' ' ')
    for cmd in ${cmds}; do
        if [[ ${cmd} =~ ^EXTINF:.* ]]; then
            file=$(echo "${cmd}" | cut -d ',' -f 2)
            url=${base_url}${file}
            echo ${url}
        else
            :
        fi
    done
}

m3u8c_download() {
    wget \
        --input-file="${LIST_FILE_NAME}" \
        --no-verbose \
        --append-output="${WGET_LOG_NAME}" \
        --tries=30 \
        --retry-connrefused \
        --waitretry=10 \
        --user-agent="${WGET_USER_AGENT}"
}

m3u8c_convert() {
    ffmpeg \
        -protocol_whitelist file,http,https,tcp,tls,crypto \
        -allowed_extensions ALL \
        -i "${M3U8_FILE_NAME}" \
        -movflags faststart \
        -c copy \
        -bsf:a aac_adtstoasc \
        "${OUT_VID_NAME}" \
        1>"${FFMPEG_LOG_NAME}" \
        2>"${FFMPEG_ERR_LOG_NAME}"
}

m3u8c_main() {
    is_force=false
    while getopts i:b:d:fm:h OPT; do
        case $OPT in
        i) # input
            m3u8_path=$OPTARG
            ;;
        b) # base url
            base_url=$OPTARG
            ;;
        d) # drm file
            drm_path=$OPTARG
            ;;
        f) # force
            is_force=true
            ;;
        m) # manual
            manual=$OPTARG
            ;;
        h) # help
            m3u8c_show_usage
            exit 0
            ;;
        esac
    done

    # args check
    if [ -z "${m3u8_path}" ] || [ -z "${base_url}" ]; then
        m3u8c_show_usage
        exit 1
    fi

    if [ ! -e ${m3u8_path} ]; then
        echo "input file not exist." && exit 1
    fi

    if [ -n "${manual}" ] && ! ([ "${manual}" == "listing" ] || [ "${manual}" == "download" ] || [ "${manual}" == "convert" ]); then
        m3u8c_show_usage
        exit 1
    fi

    # process
    if [ "${is_force}" == "true" ]; then
        rm -rf "${TEMP_DIR_NAME}"
    fi

    if [ -z "${manual}" ] && [ -e "${TEMP_DIR_NAME}" ]; then
        echo "temp dir exist." && exit 1
    fi
    mkdir -p "${TEMP_DIR_NAME}"

    cp "${m3u8_path}" "${TEMP_DIR_NAME}/${M3U8_FILE_NAME}"
    if [ -e "${drm_path}" ]; then
        cp "${drm_path}" "${TEMP_DIR_NAME}"
    fi

    cd "${TEMP_DIR_NAME}"
    # listing
    if [ -z "${manual}" ] || [ "${manual}" == "listing" ]; then
        m3u8c_urllisting >"${LIST_FILE_NAME}"
        if [ ! -s "${LIST_FILE_NAME}" ]; then
            echo "urllisting failed." && exit 1
        fi
    fi

    # donwload
    if [ -z "${manual}" ] || [ "${manual}" == "download" ]; then
        m3u8c_download ||
            (echo "wget failed." && exit 1)
    fi

    # convert
    if [ -z "${manual}" ] || [ "${manual}" == "convert" ]; then
        m3u8c_convert ||
            (echo "ffmepg failed." && exit 1)
    fi

}

m3u8c_main $@
