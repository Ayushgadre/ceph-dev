#!/bin/bash

set -e

# Env. vars used in vstart
export EC_PATH="$CEPH_LIB"/erasure-code
export OBJCLASS_PATH=/usr/lib64/rados-classes

ln -sf "$EC_PATH"/* "$CEPH_LIB"
ln -sf "$OBJCLASS_PATH"/* "$CEPH_LIB"

if [[ -z "$CEPH_RPM_REPO_DIR" ]]; then
    # The dashboard is a separate noarch package since v14.1
    export MGR_PYTHON_PATH=/usr/share/ceph/mgr
    if [[ ! -d "$MGR_PYTHON_PATH" ]]; then
        export MGR_PYTHON_PATH="$CEPH_LIB"/mgr
    fi
fi

exec "$@"
