#!/bin/bash

set -e

[[ -z "$CEPH_VERSION" ]] && export CEPH_VERSION=$("$CEPH_BIN"/ceph -v | awk '{ print substr($3,1,2) }')
[[ "$CEPH_VERSION" == 'De' ]] && export CEPH_VERSION=1000000
[[ -z "$MGR" ]] && export MGR=1
[[ -d "$MGR_PYTHON_PATH"/dashboard/frontend ]] && export IS_UPSTREAM_LUMINOUS=0
[[ -z "$RGW" ]] && export RGW=1

export IS_CEPH_RPM=$(hostname | grep "\-rpm" | wc -l)
export IS_FIRST_CLUSTER=$(hostname | grep -v cluster | wc -l)

[[ ("$IS_CEPH_RPM" == 0 || -n "$CEPH_RPM_REPO_DIR") && "$IS_UPSTREAM_LUMINOUS" == 0 && "$IS_FIRST_CLUSTER" == 1 ]] \
    && export FRONTEND_BUILD_REQUIRED=1

if [[ "$RGW_MULTISITE" == 1 ]]; then
    export RGW=0

    if [[ "$IS_FIRST_CLUSTER" == 0 ]]; then
        export FS=0
        export MDS=0
        export MGR=0
        export MON=1
    fi
fi

RGW_DEBUG=''
VSTART_OPTIONS='-n'
if [[ "$CEPH_DEBUG" == 1 ]]; then
    RGW_DEBUG='--debug-rgw=20 --debug-ms=1'
    VSTART_OPTIONS="$VSTART_OPTIONS -d"
fi
export RGW_DEBUG
export VSTART_OPTIONS

HTTP_PROTO='http'
if [[ "$DASHBOARD_SSL" == 1 ]]; then
    HTTP_PROTO='https'
fi
export HTTP_PROTO
export CEPH_MGR_DASHBOARD_PORT=$(($CEPH_PORT + 1000))
