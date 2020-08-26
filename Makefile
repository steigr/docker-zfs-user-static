DOCKER_IMAGE_NAME ?= zfs-static

REPO_PREFIX ?= quay.io/steigr

ZFS_REPO    ?= zfsonlinux/zfs
ZFS_VERSION ?= 2.0.0-rc1

ifeq ($(ZFS_VERSION),master)
DOCKER_IMAGE_VERSION := latest
else
DOCKER_IMAGE_VERSION := v$(ZFS_VERSION)
endif

image:
	docker build --build-arg=ZFS_VERSION=$(ZFS_VERSION) --tag=$(REPO_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION) --file=Dockerfile .

push: image
	docker push $(REPO_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)

all:
	make ZFS_VERSION=master
	curl -sL https://api.github.com/repos/$(ZFS_REPO)/releases | jq -r '.[].name' | grep zfs- | cur -f2- -d- | sort -rn | xargs -n1 -I{} -r -t  make ZFS_VERSION={}
