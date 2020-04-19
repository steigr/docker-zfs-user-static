set -x
set -eo pipefail

dnf install -y dnf-plugins-core rpm-build yasm make

cd $(mktemp -d)
trap "rm -rf $PWD" EXIT
dnf builddep -y krb5
dnf download --source krb5
rpm -i krb5-*.src.rpm && rm krb5-*.src.rpm
cd ~/rpmbuild
sed -i 's#enable-shared#enable-static --disable-shared#' SPECS/krb5.spec
rpmbuild -bc SPECS/krb5.spec
make -C BUILD/krb5-*/src install
