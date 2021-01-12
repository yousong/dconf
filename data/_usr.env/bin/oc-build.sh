#!/usr/bin/env bash

set -o errexit

dockerRepo=registry.cn-beijing.aliyuncs.com/yousong/onecloud

repoRoot="$(pwd)"
while [ "$repoRoot" != "/" ]; do
	if [ -f "$repoRoot/go.mod" ]; then
		repoName="$(basename "$repoRoot")"
		break
	fi
	repoRoot="$(readlink -f "$repoRoot/..")"
done
if [ "$repoRoot" = "/" ]; then
	echo "$0: Where am I" >&2
	exit 1
fi

set -o xtrace

build_onecloud() {
	local name="$1"; shift

	if [ -z "$name" ]; then
		echo "usage: $0 <name>" >&2
		echo "" >&2
		ls build/docker/Dockerfile.* | sed -e 's/^/  /' >&2
		exit 1
	fi

	cd "$repoRoot"
	docker buildx build -f build/docker/Dockerfile.$name -t "${dockerRepo}:$name" .
	docker push "${dockerRepo}:$name"
}

build_onecloud_ee() {
	local name="$1"; shift

	if [ -z "$name" ]; then
		echo "usage: $0 <name>" >&2
		echo "" >&2
		ls build/docker/Dockerfile.* | sed -e 's/^/  /' >&2
		exit 1
	fi

	local fs
	case "$name" in
		yunionapi)
			fs="cmd/cloudmon cmd/ws cmd/yunionapi"
			;;
		*)
			fs=cmd/$name
			;;
	esac

	cd "$repoRoot"
	make \
		-f "$repoRoot/../onecloud/Makefile.common.mk" \
		docker-alpine-build \
		ModName="yunion.io/x/${repoRoot##*/}" \
		F="$fs" \

	docker buildx build -f build/docker/Dockerfile.$name -t "${dockerRepo}:$name" .
	docker push "${dockerRepo}:$name"
}

build_onecloud_operator() {
	docker run --rm \
		-v $repoRoot:/root/go/src/yunion.io/x/$repoName \
		-v $repoRoot/_output/alpine-build:/root/go/src/yunion.io/x/$repoName/_output \
		-v $repoRoot/_output/alpine-build/_cache:/root/.cache \
		registry.cn-beijing.aliyuncs.com/yunionio/alpine-build:1.0-3 \
		/bin/sh -c "set -ex; cd /root/go/src/yunion.io/x/$repoName;
			make;
			chown -R $(id -u):$(id -g) _output;
			find _output/bin -type f |xargs ls -lh"

	docker buildx build -f images/onecloud-operator/Dockerfile -t "${dockerRepo}:operator" .
	docker push "${dockerRepo}:operator"
}

build_yunionapi() {
	cd "$repoRoot"
	docker buildx build -f Dockerfile -t "$dockerRepo:yunionapi" .
	docker push "$dockerRepo:yunionapi"
}

build_sdnagent() {
	cd "$repoRoot"
	docker buildx build -f "$repoRoot/build/docker/Dockerfile" -t "$dockerRepo:sdnagent" .
	docker push "$dockerRepo:sdnagent"
}

"build_${repoName//-/_}" "$@"
