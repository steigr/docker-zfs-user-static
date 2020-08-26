set -x
set -eo pipefail

export ZFS_VERSION=${ZFS_VERSION:-master}

dnf install -y git-core glibc-devel glibc-static zlib-devel zlib-static gettext-devel libtool libuuid-devel libblkid-devel libtirpc-devel openssl-devel openssl-static libaio-devel

cd $(mktemp -d --suffix=.zfs)
trap "rm -rf $PWD" EXIT

git clone https://github.com/openzfs/zfs zfs
cd zfs

# Check out the correct version
[[ ${ZFS_VERSION} = "master" ]] || git checkout "zfs-${ZFS_VERSION}"

# Apply patch for specific versions
[[ ! ${ZFS_VERSION} = "0.8.3" ]] ||curl -sL https://github.com/openzfs/zfs/commit/af09c050e95bebbaeca52156218f3f91e8c9951a.patch | patch -p1

./autogen.sh
./configure --with-config=user --enable-static --disable-shared --prefix=/usr --sysconfdir=/etc --localstatedir=/var
./scripts/make_gitrev.sh
make -C lib -j8
find . -name '*.a' | while read staticLib; do
  echo install -m 0644 -o root -g root -D ${staticLib} /usr/lib64/$(basename ${staticLib}) | sh -x
done

make -C cmd -j8
cd cmd

for dir in *; do
  [[ -d ${dir} ]] || continue

  ls ${dir}/*.c 2>/dev/null || continue
  [[ ! ${dir} = "raidz_test" ]] || continue
  pushd ${dir}

  find * -maxdepth 0 -type f -executable | xargs -n1 basename | while read cmd; do
    if [[ -f ${cmd} ]]; then
      if ldd ${cmd} | grep -q 'not a dynamic executable'; then
        echo ${cmd} is static
      else
        rm -f ${cmd}
      fi
    fi
    if [[ ! -f ${cmd} ]]; then
      objects="$(find . -name '*.o' -type f)"
      if [[ "$objects" ]]; then
        gcc -std=gnu99 -Wall -Wstrict-prototypes -fno-strict-aliasing -fno-omit-frame-pointer -Wl,--allow-multiple-definition -g -O2 -static -o ${cmd} $objects $(find ../../lib/* -name '*.a' | xargs) /usr/lib64/libtirpc.a /usr/lib64/libpthread.a /usr/lib64/libuuid.a /usr/lib64/libblkid.a /usr/lib64/libcrypto.a /usr/lib64/libdl.a /usr/lib64/libudev.a /usr/lib64/libz.a /usr/lib64/librt.a /usr/lib64/libm.a /usr/lib64/libc.a
      fi
    fi

    if [[ -f ${cmd} ]]; then
      if file ${cmd} | grep -q 'ELF'; then
        strip -s ${cmd} || true
        [[ ! -f /bin/${cmd} ]] || rm -f /bin/${cmd}
        # only compress when UPX is installed, space-savings: ~6% ( 22.6 MB --> 24.1 MB )
        command -v upx && upx -9 -o/bin/${cmd} ${cmd} || install -m 0755 ${cmd} /bin/${cmd}
      fi
    fi
  done
  popd
done
