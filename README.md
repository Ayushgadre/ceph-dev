# RHCS Dashboard Dev. Env.

## Installation

* Clone Ceph:
```
git clone git@github.com:ceph/ceph.git
```

* If it doesn't exist, create a local directory for **ccache**. Example:
```
mkdir -p ~/.ccache
```

* Clone rhcs-dashboard/ceph-dev:
```
git clone git@github.com:rhcs-dashboard/ceph-dev.git
cd ceph-dev
```

* Install [Docker Compose](https://docs.docker.com/compose/install/). If your OS is Fedora, run this:
```
sudo bash ./scripts/docker/install-docker-compose-fedora.sh
```

* Create *.env* file from template and set values:
```
cp .env.example .env

CEPH_REPO_DIR=/path/to/your/local/ceph/repo
HOST_CCACHE_DIR=/path/to/your/local/.ccache/dir

DASHBOARD_HOST_PORT=4200    (example: set 5200 if you want to open the dashboard at http://localhost:5200)
```

* Build Ceph:
```
docker-compose run --rm ceph /docker/build-ceph.sh
```

## Usage

* Start ceph & dashboard:
```
docker-compose up -d ceph
```

* Display logs:
```
docker-compose logs -f ceph
```

You can open the dashboard at http://localhost:$DASHBOARD_HOST_PORT when you see something like this in the logs:
```
ceph    | ℹ ｢wdm｣: Compiled successfully.
```

* Stop all:
```
docker-compose down
```

* Restart dashboard:
```
docker-compose exec ceph /docker/restart-dashboard.sh
```

## Git hooks

* Add pre-commit:
```
cp scripts/git/pre-commit.sh /path/to/your/local/ceph/.git/hooks/pre-commit
```
