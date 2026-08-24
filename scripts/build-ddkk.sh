#!/bin/sh
# usage: build-ddkk.sh <target>
set -e

TARGET=${1:-android16-6.12}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMAGE=docker.cnb.cool/ylarod/ddk/ddk-min:${TARGET}
RUST_IMAGE=docker.cnb.cool/ylarod/ddk/ddk-min:android16-6.12
KDIR=/opt/ddk/kdir/${TARGET}
RUST_KDIR=/opt/ddk/kdir/android16-6.12
RUST_SUPPORT_DIR="$ROOT/deps/rust_support"
CACHE=${RUST_SUPPORT_CACHE:-$ROOT/.cache}
REV=$(awk '$1=="rust_support" {print $2; exit}' "$ROOT/deps.lst")
CACHE_DIR="$CACHE/rust_support/$REV/$TARGET"
OUT="$ROOT/out/$TARGET"

if [ ! -d "$RUST_SUPPORT_DIR" ]; then
	echo "run scripts/fetch-deps.sh first"
	exit 1
fi

mkdir -p "$CACHE" "$OUT"

if [ ! -f "$CACHE_DIR/rust_support.ko" ]; then
	echo "== build rust_support cache =="
	(cd "$RUST_SUPPORT_DIR" && ./scripts/build-ddkk.sh "$TARGET")
	mkdir -p "$CACHE_DIR"
	cp -a "$RUST_SUPPORT_DIR/out/$TARGET/." "$CACHE_DIR/"
fi

echo "== compile Rust module object =="
docker run --rm \
	-e KDIR="$RUST_KDIR" \
	-e VER="$TARGET" \
	-e RUST_REV="$REV" \
	-e RUST_SUPPORT_CACHE="$CACHE" \
	-v "$ROOT":/src \
	-v "$CACHE":/cache \
	-w /src \
	"$RUST_IMAGE" \
	sh -c '
		set -e
		RUSTC=/opt/ddk/rust/rust-1.82.0/bin/rustc
		export RUST_MODFILE=mymod
		COMMON="--edition=2021 -Cpanic=abort -Cembed-bitcode=n -Clto=n"
		COMMON="$COMMON -Ccodegen-units=1 -Csymbol-mangling-version=v0"
		COMMON="$COMMON -Crelocation-model=static"
		COMMON="$COMMON --target=aarch64-unknown-none -Ctarget-feature=-neon"
		OUT=/src/out/'"$TARGET"'
		RUST_OUT=/cache/rust_support/$RUST_REV/'"$TARGET"'/rust
		mkdir -p "$OUT"
		# shellcheck disable=SC2086
		"$RUSTC" $COMMON \
			--crate-type rlib \
			--crate-name mymod \
			-L "$RUST_OUT" \
			--extern kernel \
			--extern core \
			--extern compiler_builtins \
			--extern macros \
			--cfg MODULE \
			--cfg CONFIG_KUNIT \
			--emit=obj="$OUT/mymod_rust.o" \
			--sysroot=/dev/null /src/src/lib.rs
		llvm-objcopy \
			--redefine-sym init_module=rust_mymod_init_module \
			--redefine-sym cleanup_module=rust_mymod_cleanup_module \
			"$OUT/mymod_rust.o"
		ALIAS_MAP=/cache/rust_support/$RUST_REV/'"$TARGET"'/rust_sym_map.txt
		if [ -f "$ALIAS_MAP" ]; then
			echo "== apply rust_support short aliases =="
			args=""
			while read -r long short; do
				[ -z "$long" ] && continue
				args="$args --redefine-sym $long=$short"
			done < "$ALIAS_MAP"
			# shellcheck disable=SC2086
			llvm-objcopy $args "$OUT/mymod_rust.o"
		fi
		touch "$OUT/.mymod_rust.o.cmd"
	'

echo "== link $TARGET/mymod.ko =="
docker run --rm \
	-e KDIR="$KDIR" \
	-e VER="$TARGET" \
	-e RUST_REV="$REV" \
	-v "$ROOT":/src \
	-v "$CACHE":/cache \
	-w /src \
	"$IMAGE" \
	sh -c 'make VER="$1" KBUILD_EXTRA_SYMBOLS=/cache/rust_support/$2/'"$TARGET"'/Module.symvers' sh "$TARGET" "$REV"

echo "-> $OUT/mymod.ko"
find "$OUT" -name "*.ko"
