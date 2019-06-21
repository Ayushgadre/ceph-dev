#!/bin/bash

set -e

source /docker/set-start-env.sh

# Always run this (needed to run e2e tests through 'docker-compose run ...'):
/docker/set-dev-server-proxy.sh

# Build frontend ('dist' dir required by dashboard module):
if [[ "$FRONTEND_BUILD_REQUIRED" == 1 ]]; then
    cd "$MGR_PYTHON_PATH"/dashboard/frontend

    run_npm_build() {
        if [[ "$CEPH_VERSION" == '13' ]]; then
            rm -rf package-lock.json node_modules/@angular/cli
            npm update @angular/cli
        fi

        npm install -f
        npm run build
    }

    run_npm_build || (rm -rf node_modules && run_npm_build)

    # Start dev server
    if [[ "$DASHBOARD_DEV_SERVER" == 1 ]]; then
        npm run start &
    else
        npm run build -- --watch --deleteOutputPath=false &
    fi
fi

rm -rf "$CEPH_CONF_PATH" && mkdir -p "$CEPH_CONF_PATH"

cd /ceph/build
../src/vstart.sh ${VSTART_OPTIONS}

echo 'vstart.sh completed!'

# Configure Object Gateway:
/docker/set-rgw.sh

# Enable prometheus module
if [[ "$IS_FIRST_CLUSTER" == 1 ]]; then
    "$CEPH_BIN"/ceph mgr module enable prometheus
    echo 'Prometheus mgr module enabled.'
fi

# Upstream luminous start ends here
if [[ "$IS_UPSTREAM_LUMINOUS" != 0 ]]; then
    exit 0
fi

# Disable ssl (if selected)
readonly VSTART_HAS_SSL_FLAG=$(cat /ceph/src/vstart.sh | grep DASHBOARD_SSL | wc -l)
if [[ "$DASHBOARD_SSL" == 0 && "$VSTART_HAS_SSL_FLAG" == 0 && "$IS_FIRST_CLUSTER" == 1 ]]; then
    echo "Disabling SSL..."

    SSL_OPTIONS='--force'
    if [[ "$CEPH_VERSION" == 13 ]]; then
        SSL_OPTIONS=''
    fi

    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/ssl false $SSL_OPTIONS
    "$CEPH_BIN"/ceph config set mgr mgr/dashboard/x/server_port "$CEPH_MGR_DASHBOARD_PORT" $SSL_OPTIONS
    /docker/restart-dashboard.sh

    echo "SSL disabled."
fi

# Upstream mimic start ends here
if [[ "$CEPH_VERSION" == '13' || "$IS_FIRST_CLUSTER" == 0 ]]; then
    exit 0
fi

# Create dashboard "test" user:
"$CEPH_BIN"/ceph dashboard ac-user-create test test

# Configure grafana
set_grafana_api_url() {
    while true; do
        GRAFANA_IP=$(getent ahosts grafana | tail -1 | awk '{print $1}')
        if [[ -n "$GRAFANA_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-grafana-api-url "http://$GRAFANA_IP:$GRAFANA_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_grafana_api_url &

# RHCS 3.2 beta start ends here
if [[ "$CEPH_VERSION" == '12' ]]; then
    exit 0
fi

# Configure alertmanager
set_alertmanager_api_host() {
    while true; do
        ALERTMANAGER_IP=$(getent ahosts alertmanager | tail -1 | awk '{print $1}')
        if [[ -n "$ALERTMANAGER_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-alertmanager-api-host "http://$ALERTMANAGER_IP:$ALERTMANAGER_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_alertmanager_api_host &

# Configure prometheus
set_prometheus_api_host() {
    while true; do
        PROMETHEUS_IP=$(getent ahosts prometheus | tail -1 | awk '{print $1}')
        if [[ -n "$PROMETHEUS_IP" ]]; then
            "$CEPH_BIN"/ceph dashboard set-prometheus-api-host "http://$PROMETHEUS_IP:$PROMETHEUS_HOST_PORT"

            break
        fi

        sleep 3
    done
}
set_prometheus_api_host &
