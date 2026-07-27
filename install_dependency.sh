#!/bin/bash
set -e

for cmd in git gh make go; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed."
        exit 1
    fi

    $cmd --version | head -n 1
done

download_and_gzip_rule() {
    local asset_name="$1"

    gh release download latest -R MetaCubeX/meta-rules-dat -p "$asset_name" -D "$tmp_rules_dir"
    gzip "$tmp_rules_dir/$asset_name"
    mv -f "$tmp_rules_dir/$asset_name.gz" "$rules_dir/$asset_name.gz"
}

echo "Building mihomo from koitococo/mihomo Meta..."
rm -rf clash.meta
mkdir clash.meta

mihomo_build_dir=$(mktemp -d)
trap 'rm -rf "$mihomo_build_dir"' EXIT

git clone --depth 1 --branch Meta https://github.com/koitococo/mihomo.git "$mihomo_build_dir"
(
    cd "$mihomo_build_dir"
    make darwin-amd64 darwin-arm64
)

cp "$mihomo_build_dir/bin/mihomo-darwin-amd64" clash.meta/
cp "$mihomo_build_dir/bin/mihomo-darwin-arm64" clash.meta/
rm -rf "$mihomo_build_dir"
trap - EXIT

echo "Build complete."

cd clash.meta
echo "Create Universal core"
lipo -create -output com.metacubex.ClashX.ProxyConfigHelper.meta mihomo-darwin-amd64* mihomo-darwin-arm64*
chmod +x com.metacubex.ClashX.ProxyConfigHelper.meta

echo "Update meta core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q com.metacubex.ClashX.ProxyConfigHelper.meta)/g" ../ClashX/General/ClashProcess.swift
grep -n "static let metaCoreMd5" ../ClashX/General/ClashProcess.swift

echo "Gzip Universal core"
gzip com.metacubex.ClashX.ProxyConfigHelper.meta
cp com.metacubex.ClashX.ProxyConfigHelper.meta.gz ../ClashX/Resources/
cd ..

echo "delete old files"
rm -rf ./ClashX/Resources/meta-rules-dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*

rules_dir="./ClashX/Resources/meta-rules-dat"
mkdir -p "$rules_dir"
tmp_rules_dir="clash.meta"

echo "install mmdb"
download_and_gzip_rule "country.mmdb"

echo "install geosite"
download_and_gzip_rule "geosite.dat"

echo "install geoip"
download_and_gzip_rule "geoip.dat"

echo "install BundleMRS"
download_and_gzip_rule "BundleMRS.7z"


echo "install yacd dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/MetaCubeX/Yacd-meta.git dashboard/yacd --depth=1
cd dashboard/yacd
rm -rf *.webmanifest *.js CNAME .git
cd ../../

echo "install XD dashboard"
git clone -b gh-pages https://github.com/metacubex/metacubexd.git dashboard/xd --depth=1
cd dashboard/xd
rm -rf *.webmanifest CNAME .git
cd ../../

echo "install zashboard"
git clone -b gh-pages https://github.com/Zephyruso/zashboard.git dashboard/zashboard --depth=1
cd dashboard/zashboard
rm -rf *.webmanifest CNAME .git
