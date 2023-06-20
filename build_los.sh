#!/bin/bash

DEVICE="nx563j"  # Default device option is nx563j
TARGET="userdebug"  # Default target option is userdebug
BUILD_TYPE="bacon"  # Default build type option is bacon

# Record current directory address
SCRIPT_DIR=$(pwd)

while getopts "d:t:o:" opt; do
  case $opt in
    d)
      case $OPTARG in
        nx563j|nx606j|nx609j|nx611j|nx619j|nx651j)
          DEVICE=$OPTARG
          ;;
        *)
          echo "Invalid device option: $OPTARG" >&2
          exit 1
          ;;
      esac
      ;;
    t)
      case $OPTARG in
        userdebug|user|eng)
          TARGET=$OPTARG
          ;;
        *)
          echo "Invalid device option: $OPTARG" >&2
          exit 1
          ;;
      esac
      ;;
    o)
      case $OPTARG in
        bacon|bootimage|recoveryimage)
          BUILD_TYPE=$OPTARG
          ;;
        *)
          echo "Invalid device option: $OPTARG" >&2
          exit 1
          ;;
      esac
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

CPU_JOB_NUM=$((($(grep processor /proc/cpuinfo | awk '{field=$NF};END{print field+1}') * 2)))

function format_duration() {
  local total_seconds=$1
  local hours=$((total_seconds / 3600))
  local minutes=$(( (total_seconds % 3600) / 60 ))
  echo "$hours h $minutes min"
}

function build_target() {
  echo "<<<<<< Start building LineageOS for $DEVICE >>>>>>"
  echo '================================================'
  START_TIME=$(date +%s)
  LOG_DIRECTORY="${SCRIPT_DIR}/${DEVICE}_logs"
  mkdir -p "$LOG_DIRECTORY"
  LOG_FILE="${LOG_DIRECTORY}/build_${DEVICE}-$(date +%Y%m%d%H%M%S).log"
  cd ..
  export LC_ALL=C
  export USE_CCACHE=1
  export CCACHE_EXEC=/usr/bin/ccache
  ccache -M 50G
  source ./build/envsetup.sh
  lunch lineage_"$DEVICE"-"$TARGET"
#  mka "$BUILD_TYPE" -j"$CPU_JOB_NUM" >build.log 2>&1
  { make "$BUILD_TYPE" -j"$CPU_JOB_NUM" 2>&3 | tee "$LOG_FILE"; } 3>&1
  END_TIME=$(date +%s)
  ELAPSED_TIME=$((END_TIME - START_TIME))
  formatted_duration=$(format_duration "$ELAPSED_TIME")
  echo "Total build time: $formatted_duration"
}

build_target

if grep -q "build completed successfully" "$LOG_FILE"; then
  echo '================================================'
  echo 'Build succeeded'
  exit 0
else
  echo '================================================'
  echo 'Build failed'
  exit 1
fi
