###################################################
###################################################
###################################################
# Stage 1 (core): core package
###################################################
###################################################
###################################################

FROM almalinux:9 AS core

RUN set -ex \
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb

# Core
RUN dnf -y install \
    gcc gcc-c++ make git wget bzip2 man systemd procps psmisc \
    bash-completion vim-enhanced dejagnu

# Python
RUN dnf -y install \
    python3 python3-pip python3-devel

# HPC / Slurm
RUN dnf -y install \
    munge munge-devel hwloc-devel libevent-devel

# MariaDB
RUN dnf -y install \
    mariadb-server mariadb-devel

# IPC / System integration
RUN dnf -y install \
    dbus dbus-daemon dbus-devel

# JSON & parser libs
RUN dnf -y install \
    http-parser-devel json-c-devel

# cleanup
RUN dnf clean all && rm -rf /var/cache/dnf

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN pip3 install Cython nose

COPY --from=tianon/gosu /gosu /usr/local/bin/

###################################################
###################################################
###################################################
# Stage 2 (tools): Installation of PDSH PMIX OPENMPI
###################################################
###################################################
###################################################

FROM core AS tools

ARG PDSG_TAG=2.35
ARG PMIX_TAG=4.2.7
ARG OPENMPI_VERSION=5.0.8

RUN set -x \
    && wget https://github.com/chaos/pdsh/releases/download/pdsh-${PDSG_TAG}/pdsh-${PDSG_TAG}.tar.gz \
    && tar -xzvf pdsh-${PDSG_TAG}.tar.gz \
    && cd pdsh-${PDSG_TAG} \
    && ./configure \
    && make \
    && make install

RUN set -x \
    && wget https://github.com/openpmix/openpmix/releases/download/v${PMIX_TAG}/pmix-${PMIX_TAG}.tar.gz \
    && tar -xzvf pmix-${PMIX_TAG}.tar.gz \
    && cd pmix-${PMIX_TAG} \
    && mkdir /usr/local/pmix \
    && ./configure --prefix=/usr/local/pmix |& tee config.out \
    && make -j $(nproc) |& tee make.out \
    && make install |& tee install.out


RUN set -x \
    && wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-${OPENMPI_VERSION}.tar.gz \
    && tar xf openmpi-${OPENMPI_VERSION}.tar.gz \
    && cd openmpi-${OPENMPI_VERSION} \
    && CFLAGS=-I/usr/include/slurm ./configure \
    --with-slurm \
    --with-pmix=/usr/local/pmix \
    && make -j $(nproc) \
    && make install


###################################################
###################################################
###################################################
# Stage 3 (slurm): SLURM INSTALLATION (V.25.05.1.1)
###################################################
###################################################
###################################################

FROM tools AS slurm

ARG SLURM_TAG=slurm-25-05-1-1
RUN set -x \
    && git clone -b ${SLURM_TAG} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --enable-debug \
    --prefix=/usr \
    --sysconfdir=/etc/slurm \
    --with-mysql_config=/usr/bin  \
    --libdir=/usr/lib64 \
    --with-pmix=/usr/local/pmix/ \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && groupadd -r --gid=990 slurm \
    && useradd -r -g slurm --uid=990 slurm \
    && mkdir /etc/sysconfig/slurm \
    /var/spool/slurmd \
    /var/run/slurmd \
    /var/run/slurmdbd \
    /var/lib/slurmd \
    /var/log/slurm \
    /data \
    && touch /var/lib/slurmd/node_state \
    /var/lib/slurmd/front_end_state \
    /var/lib/slurmd/job_state \
    /var/lib/slurmd/resv_state \
    /var/lib/slurmd/trigger_state \
    /var/lib/slurmd/assoc_mgr_state \
    /var/lib/slurmd/assoc_usage \
    /var/lib/slurmd/qos_usage \
    /var/lib/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm* \
    && /sbin/create-munge-key

FROM slurm AS ldms
ARG LDMS_VERSION=v4.5.1

RUN set -ex\
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y install \
    automake \
    openssl \
    openssl-devel \
    pkg-config \
    libtool \
    python3-Cython \
    bison \
    flex \
    swig \
    readline \
    readline-devel \
    libevent \
    libevent-devel \
    glib2 \
    glib2-devel \
    byacc \
    librdkafka \
    librdkafka-devel \
    python3-docutils \
    jansson \
    jansson-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf


RUN set -ex \
    && mkdir -p /tmp/Source \
    && cd /tmp/Source \
    && git clone -b ${LDMS_VERSION} --depth=1 https://github.com/ovis-hpc/ovis.git ovis-${LDMS_VERSION#v} \
    && cd ovis-${LDMS_VERSION#v} \
    && ./autogen.sh \
    && mkdir build \
    && cd build \
    && ../configure --prefix=/opt/ovis \
    && make -j $(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/Source

###################################################
###################################################
###################################################
# Stage 4 (conf):  Copy slurm conf
###################################################
###################################################
###################################################

FROM ldms AS conf

COPY ./slurm/slurm.conf /etc/slurm/slurm.conf

COPY ./slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf

COPY ./slurm/cgroup.conf /etc/slurm/cgroup.conf

COPY ./slurm/plugstack.conf /etc/slurm/plugstack.conf

RUN set -x \
    && chown slurm:slurm /etc/slurm/slurmdbd.conf \
    && chmod 600 /etc/slurm/slurmdbd.conf \
    && chmod 644 /etc/slurm/slurm.conf


###################################################
###################################################
###################################################
# Stage 5: Additionnal package for test
###################################################
###################################################
###################################################

FROM conf AS stress

RUN dnf -y install epel-release && \
    dnf -y install stress && \
    dnf clean all


COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slurmdbd"]