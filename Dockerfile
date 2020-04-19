FROM fedora:31 AS builder

RUN  dnf update -y

COPY static-krb5.sh /static-krb5.sh
RUN  bash -x /static-krb5.sh

COPY static-libtirpc.sh /static-libtirpc.sh
RUN  bash -x /static-libtirpc.sh

COPY static-udev.sh /static-udev.sh
RUN  bash -x /static-udev.sh

COPY static-util-linux.sh /static-util-linux.sh
RUN  bash -x /static-util-linux.sh

ARG  ZFS_VERSION=master
COPY static-zfs.sh /static-zfs.sh
RUN  bash -x /static-zfs.sh

FROM alpine:3.11
COPY --from=builder /bin/zpool /bin/zpool
COPY --from=builder /bin/ztest /bin/ztest
COPY --from=builder /bin/zdb /bin/zdb
COPY --from=builder /bin/zvol_id /bin/zvol_id
COPY --from=builder /bin/zed /bin/zed
COPY --from=builder /bin/mount.zfs /bin/mount.zfs
COPY --from=builder /bin/zhack /bin/zhack
COPY --from=builder /bin/zfs /bin/zfs
COPY --from=builder /bin/zinject /bin/zinject
COPY --from=builder /bin/zstream /bin/zstream