#!/usr/bin/env bash
set -e # exit on error

exec 3>&1
function echo-always() {
  echo $@ 1>&3
}

function usage() {
  echo "Usage $(basename $0) -s source-image -d destination-image [-D]" 1>&2
  echo "      $(basename $0) -u image [-D]" 1>&2
  echo 1>&2
  echo " Options:" 1>&2
  echo "   -D enable debug mode" 1>&2
  echo 1>&2
}

while getopts "u:s:d:Dh" o; do
  case "${o}" in
    u)
       SOURCE=${OPTARG}
       DESTINATION=${OPTARG}
       ;;
    s) SOURCE=${OPTARG};;
    d) DESTINATION=${OPTARG};;
    D) DEBUG=true;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      echo "Unrecognized argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${SOURCE}" ]; then
    usage
    echo "Source required" 1>&2
    exit 1
fi

if [ -z "${DESTINATION}" ]; then
    usage
    echo "Destination required" 1>&2
    exit 1
fi

if [ -n "${DEBUG}" ]; then
   set -x # if DEBUG is defined, print all commands
else
   exec 1>/dev/null
fi

if [ "${SOURCE}" == "${DESTINATION}" ]; then
   echo-always Republishing ${SOURCE}
else
   echo-always Publishing ${SOURCE} as ${DESTINATION}
fi

docker pull "${SOURCE}"
SOURCE_ARCH=$(docker inspect "${SOURCE}" | jq -r '.[].Architecture')
if [ "${SOURCE_ARCH}" == "arm" ]; then
   echo Source is already marked as arm architecture
   if [ "${SOURCE}" == "${DESTINATION}" ]; then
      echo-always Source is already arm and is the same as destination. Nothing to do.
      exit 0
   fi
   docker tag "${SOURCE}" "${DESTINATION}"
else
   echo "${SOURCE} is marked as ${SOURCE_ARCH} architecture"
   docker-copyedit/docker-copyedit.py from "${SOURCE}" into "${DESTINATION}" set arch arm 1>&3
fi

docker push "${DESTINATION}" 1>&3
