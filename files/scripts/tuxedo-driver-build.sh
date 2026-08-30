#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Install packages
rpm-ostree install rpm-build rpmdevtools kmodtool

# Exec perms for symlink script
chmod +x /usr/bin/fixtuxedo
# And autorun
systemctl enable /etc/systemd/system/fixtuxedo.service

# Build and install tuxedo drivers

export HOME=/tmp

cd /tmp

rpmdev-setuptree

git clone https://github.com/gladion136/tuxedo-drivers-kmod

# Build for the kernel that will actually ship in this image, not the build
# host's own kernel: build.sh defaults to `uname -r`, which is the container
# build host's kernel (e.g. the Ubuntu GitHub Actions runner) and has no
# matching kernel-devel inside this Fedora rootfs, so kmodtool would silently
# skip compiling the module for it.
export KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
export FEDORA=44

cd tuxedo-drivers-kmod/
./build.sh "${KERNEL_VERSION}"
cd ..

# Extract the Version value from the spec file
export TD_VERSION=$(cat tuxedo-drivers-kmod/tuxedo-drivers-kmod-common.spec | grep -E '^Version:' | awk '{print $2}')

echo "Kernel version: ${KERNEL_VERSION}"
echo "Tuxedo version: ${TD_VERSION}"

# Install the base/common packages plus the kmod pre-built for the exact
# kernel baked into this image. The akmod-* package is intentionally skipped:
# its %post scriptlet tries to build the module immediately via akmods, which
# now refuses to run as root (Fedora 44 regression, see
# https://github.com/ublue-os/bazzite/issues/5106) and isn't needed anyway
# since we already ship a matching precompiled module for this exact kernel.
rpm-ostree install ~/rpmbuild/RPMS/x86_64/tuxedo-drivers-kmod-$TD_VERSION-1.fc$FEDORA.x86_64.rpm ~/rpmbuild/RPMS/x86_64/tuxedo-drivers-kmod-common-$TD_VERSION-1.fc$FEDORA.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kmod-tuxedo-drivers-$KERNEL_VERSION-$TD_VERSION-1.fc$FEDORA.x86_64.rpm

# Hacky workaround to make TCC install elsewhere
mkdir -p /usr/share
rm /opt
ln -s /usr/share /opt

rpm-ostree install tuxedo-control-center

cd /
rm /opt
ln -s var/opt /opt
ls -al /

rm /usr/bin/tuxedo-control-center
ln -s /usr/share/tuxedo-control-center/tuxedo-control-center /usr/bin/tuxedo-control-center

sed -i 's|/opt|/usr/share|g' /etc/systemd/system/tccd.service
sed -i 's|/opt|/usr/share|g' /usr/share/applications/tuxedo-control-center.desktop

systemctl enable tccd.service

systemctl enable tccd-sleep.service

systemctl enable podman.socket