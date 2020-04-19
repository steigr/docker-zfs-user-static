set -x
set -eo pipefail

dnf install -y dnf-plugins-core rpm-build make gnu-efi gnu-efi-devel

cd $(mktemp -d)
# trap "rm -rf $PWD" EXIT
dnf builddep -y systemd
dnf download --source systemd
rpm -i systemd-*.src.rpm && rm systemd-*.src.rpm
cd ~/rpmbuild
sed -i 's#-Dman=true#-Dman=true -Dstatic-libudev=true#' SPECS/systemd.spec
rpmbuild -bc SPECS/systemd.spec
find BUILD/systemd-* -name 'libudev*.a' | xargs -n1 -I{} -r -t sh -c 'install -m 0644 {} /usr/lib64/$(basename {})'