# rust_lkm_template

Rust LKM template for the Dere3046 LKM ecosystem. It depends on
rust_support through KMSDK and caches rust_support build outputs by
rev and target.

## build

```sh
scripts/fetch-deps.sh
scripts/build-ddkk.sh android16-6.12
```

full targets: android12-5.10 android13-5.10 android13-5.15
android14-5.15 android14-6.1 android15-6.6 android16-6.12

## cache

rust_support outputs are cached at:

```sh
${RUST_SUPPORT_CACHE:-.cache}/rust_support/<rev>/<target>
```

Delete the cache entry to force a rust_support rebuild.
