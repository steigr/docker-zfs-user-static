set -x
set -eo pipefail

dnf install -y dnf-plugins-core rpm-build yasm make

cd $(mktemp -d)
trap "rm -rf $PWD" EXIT
dnf builddep -y libtirpc
dnf download --source libtirpc
rpm -i libtirpc-*.src.rpm && rm libtirpc-*.src.rpm
cd ~/rpmbuild
sed -i 's#enable-shared#enable-static --disable-shared#' SPECS/libtirpc.spec
rpmbuild -bc SPECS/libtirpc.spec
make -C BUILD/libtirpc-*/src install
