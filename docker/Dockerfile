FROM almalinux:9@sha256:375aa0df1af54a6ad8f4dec9ec3e0df16feec385c4fb761ac5c5ccdd829d0170 AS builder

################################################################################
# Building
################################################################################


ARG PDSH_VERSION=2.35
ARG PMIX_VERSION=4.2.7
ARG OPENMPI_VERSION=5.0.8
ARG SLURM_VERSION=25-05-1-1
ARG LDMS_VERSION=v4.5.1

RUN set -ex \
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y install \
        wget \
        tar \
        gcc \
        gcc-c++ \
        make \
        git \
        python3 \
        python3-devel \
        python3-pip \
        munge \
        munge-devel \
        mariadb-server \
        mariadb-devel \
        http-parser-devel \
        json-c-devel \
        hwloc \
        hwloc-devel \
        librdkafka \
        librdkafka-devel \
        dbus \
        dbus-devel \
        systemd \
        #LDMS dependencies that are not above
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
        python3-docutils \
        jansson \
        jansson-devel \
        && dnf clean all \
        && rm -rf /var/cache/dnf \
        && pip3 install Cython nose

# Building PDSH
RUN set -x \
    && wget https://github.com/chaos/pdsh/releases/download/pdsh-${PDSH_VERSION}/pdsh-${PDSH_VERSION}.tar.gz \
    && tar -xzvf pdsh-${PDSH_VERSION}.tar.gz \
    && cd pdsh-${PDSH_VERSION} \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf pdsh-${PDSH_VERSION} pdsh-${PDSH_VERSION}.tar.gz

# Building PMIX
RUN set -x \
    && wget https://github.com/openpmix/openpmix/releases/download/v${PMIX_VERSION}/pmix-${PMIX_VERSION}.tar.gz \
    && tar -xzvf pmix-${PMIX_VERSION}.tar.gz \
    && cd pmix-${PMIX_VERSION} \
    && mkdir /usr/local/pmix \
    && ./configure --prefix=/usr/local/pmix \
    && make -j $(nproc) \
    && make install \
    && cd .. \
    && rm -rf pmix-${PMIX_VERSION} pmix-${PMIX_VERSION}.tar.gz

# Building OpenMPI with PMIX and SLURM support
RUN set -x \
    && wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-${OPENMPI_VERSION}.tar.gz \
    && tar xf openmpi-${OPENMPI_VERSION}.tar.gz \
    && cd openmpi-${OPENMPI_VERSION} \
    && CFLAGS=-I/usr/include/slurm ./configure \
    --with-slurm \
    --with-pmix=/usr/local/pmix \
    && make -j $(nproc) \
    && make install \
    && cd .. \
    && rm -rf openmpi-${OPENMPI_VERSION} openmpi-${OPENMPI_VERSION}.tar.gz

# Building SLURM
RUN set -x \
    && git clone -b slurm-${SLURM_VERSION} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && ./configure --enable-debug \
    --prefix=/usr \
    --sysconfdir=/etc/slurm \
    --with-mysql_config=/usr/bin \
    --libdir=/usr/lib64 \
    --with-pmix=/usr/local/pmix/ \
    && make -j $(nproc) \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm

# Building LDMS
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

################################################################################
# Runtime
#################################################################################

FROM almalinux:9@sha256:375aa0df1af54a6ad8f4dec9ec3e0df16feec385c4fb761ac5c5ccdd829d0170 AS runtime


RUN set -ex \
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y install \
        munge \
        munge-devel \
        mariadb-server \
        python3 \
        python3-pip \
        hwloc \
        librdkafka \
        dbus \
        systemd \
        openssl \
        glib2 \
        jansson \
        readline \
        libevent \
        docker \
        && dnf clean all \
        && rm -rf /var/cache/dnf \
        && pip3 install Cython nose

# Copy lib and bin from builder
COPY --from=builder /usr/local/pmix /usr/local/pmix
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/bin/ /usr/bin/
COPY --from=builder /usr/sbin/ /usr/sbin/
COPY --from=builder /usr/lib64/ /usr/lib64/
COPY --from=builder /etc/slurm /etc/slurm
COPY --from=builder /opt/ovis /opt/ovis
# gosu for handling permissions
COPY --from=tianon/gosu /gosu /usr/local/bin/

# Setup users and permissions
RUN set -x \
    && groupadd -r --gid=990 slurm \
    && useradd -r -g slurm --uid=990 slurm

RUN set -x \
    && mkdir -p \
    /etc/sysconfig/slurm \
    /var/spool/slurmd \
    /var/run/slurmd \
    /var/run/slurmdbd \
    /var/lib/slurmd \
    /var/log/slurm \
    /data \
    && touch \
    /var/lib/slurmd/node_state \
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


# Copy slurm config files
COPY ./slurm/slurm.conf /etc/slurm/slurm.conf
COPY ./slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY ./slurm/cgroup.conf /etc/slurm/cgroup.conf

# For LDMS
COPY ./slurm/plugstack.conf /etc/slurm/plugstack.conf

COPY ./slurm/scripts /etc/slurm/scripts/

RUN set -x \
&& chown slurm:slurm /etc/slurm/slurmdbd.conf \
&& chmod 600 /etc/slurm/slurmdbd.conf \
&& chmod 644 /etc/slurm/slurm.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slurmdbd"]