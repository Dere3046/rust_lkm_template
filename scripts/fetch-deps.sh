#!/bin/sh
# deploy rust_support through KMSDK at pinned rev
set -e

cd "$(dirname "$0")/.."

SDKREV=$(cat .sdk-version)

if [ ! -d .sdk/.git ]; then
	rm -rf .sdk
	git clone git@github.com:Dere3046/KMSDK.git .sdk
fi

case $SDKREV in
[0-9a-f]*)
	git -C .sdk fetch origin 2>/dev/null || true
	git -C .sdk checkout "$SDKREV"
	;;
esac

.sdk/scripts/sdk install

if [ -x deps/rust_support/scripts/fetch-deps.sh ]; then
	(cd deps/rust_support && ./scripts/fetch-deps.sh)
fi
