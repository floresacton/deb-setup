#!/bin/bash
set -e

PKGNAME="deb-setup"
VERSION="1.0"
ARCHS=("amd64" "i386" "arm64")
SECTION="misc"
PRIORITY="optional"
MAINTAINER="Miguel Flores-Acton <floresacton@gmail.com>"
DESCRIPTION="Package to automatically install all my packages"

#GPG_KEY="floresacton@gmail.com"

DIST="stable"
COMPONENT="main"

FIRST_LETTER=$(echo "${PKGNAME:0:1}" | tr '[:upper:]' '[:lower:]')

POOL_DIR="pool/main/$FIRST_LETTER/$PKGNAME"

rm -rf "packages"
rm -rf "pool"
rm -rf "dists"

mkdir -p "$POOL_DIR"

DEPS=$(awk '{printf "%s%s", sep, $0; sep=", "} END{print ""}' deps.txt)

for ARCH in "${ARCHS[@]}"; do
    BUILD_DIR="packages/$ARCH"
    CONTROL_DIR="$BUILD_DIR/DEBIAN"
    DIST_DIR="dists/$DIST/$COMPONENT/binary-$ARCH"
    DEBFILE="${PKGNAME}_${VERSION}_${ARCH}.deb"

    mkdir -p "$CONTROL_DIR"

    cat > "$CONTROL_DIR/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: $SECTION
Priority: $PRIORITY
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: $DEPS
Description: $DESCRIPTION
EOF

    mkdir -p "${BUILD_DIR}/${ARCH}/DEBIAN"
    dpkg-deb --build "$BUILD_DIR"
    cp "${BUILD_DIR}.deb" "$POOL_DIR/$DEBFILE"

    mkdir -p "$DIST_DIR"
    dpkg-scanpackages -m pool /dev/null | gzip -9 > "$DIST_DIR/Packages.gz"

    cat > "$DIST_DIR/Release" <<EOF
Archive: $DIST
Component: $COMPONENT
Origin: Local
Label: $PKGNAME repo
Architecture: $ARCH
EOF

done

rm "${BUILD_DIR}.deb"

#gpg --default-key "$GPG_KEY" --armor --detach-sign -o "$DIST_DIR/Release.gpg" "$DIST_DIR/Release"
#gpg --default-key "$GPG_KEY" --clearsign -o "$DIST_DIR/InRelease" "$DIST_DIR/Release"

echo "Package built and placed at $POOL_DIR/$DEBFILE"
