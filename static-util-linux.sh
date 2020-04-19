set -x
set -eo pipefail

dnf install -y dnf-plugins-core rpm-build make

cd $(mktemp -d)
trap "rm -rf $PWD" EXIT
dnf builddep -y util-linux
dnf download --source util-linux
rpm -i util-linux-*.src.rpm && rm util-linux-*.src.rpm
cd ~/rpmbuild
sed -i 's#enable-shared#enable-static --disable-shared#' SPECS/util-linux.spec
rpmbuild -bc SPECS/util-linux.spec
make -C BUILD/util-linux-* install
