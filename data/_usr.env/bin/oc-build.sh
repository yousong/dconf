#!/usr/bin/env bash

set -o errexit

dockerRepo=registry.cn-beijing.aliyuncs.com/yousong/onecloud

repoRoot="$(pwd)"
while [ "$repoRoot" != "/" ]; do
	if [ -f "$repoRoot/go.mod" ]; then
		repoName="$(basename "$repoRoot")"
		break
	fi
	cwd="$(readlink -f "$cwd/..")"
done
if [ "$repoRoot" = "/" ]; then
	echo "$0: Where am I" >&2
	exit 1
fi

set -o xtrace

build_onecloud() {
	local name="$1"

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

build_yunionapi() {
	cd "$repoRoot"
	docker buildx build -f Dockerfile -t "$dockerRepo:yunionapi" .
	docker push "$dockerRepo:yunionapi"
}

"build_$repoName" "$@"
