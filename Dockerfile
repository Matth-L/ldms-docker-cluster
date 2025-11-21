###################################################
###################################################
###################################################
# Stage 1 (core): core package
###################################################
###################################################
###################################################

FROM almalinux:9@sha256:375aa0df1af54a6ad8f4dec9ec3e0df16feec385c4fb761ac5c5ccdd829d0170 AS core

RUN set -ex \
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Core / convenience utilities
RUN set -ex \
    && dnf -y install \
        wget \
        bzip2 \
        perl \
        psmisc \
        gnupg \
        bash-completion \
        vim-enhanced \
        man \
        procps \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Development / build tools
RUN set -ex \
    && dnf -y install \
        gcc \
        gcc-c++ \
        make \
        git \
        dejagnu \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# System / init & dbus
RUN set -ex \
    && dnf -y install \
        systemd \
        dbus \
        dbus-daemon \
        dbus-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Munge (auth for Slurm) and related
RUN set -ex \
    && dnf -y install \
        munge \
        munge-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Python and tooling
RUN set -ex \
    && dnf -y install \
        python3 \
        python3-devel \
        python3-pip \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Database (MariaDB)
RUN set -ex \
    && dnf -y install \
        mariadb-server \
        mariadb-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Libraries used by LDMS/Slurm/OpenMPI/etc.
RUN set -ex \
    && dnf -y install \
        http-parser-devel \
        json-c-devel \
        hwloc-devel \
        libevent-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Container tooling (optional)
RUN set -ex \
    && dnf -y install docker \
    && dnf clean all \
    && rm -rf /var/cache/dnf


# Set Python alternatives
RUN alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install Python packages
RUN pip3 install Cython nose

# Copy gosu for handling permissions
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
# SLURM INSTALLATION (V.25.05.1.1)
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


###################################################
###################################################
###################################################
# LDMS INSTALL
# Not modular, v.4.4.5, located in /opt/ovis (like the demo)
###################################################
###################################################
###################################################

FROM slurm AS ldms

COPY ldms/ldms_installer.sh .
RUN set -x \
    chmod +x ldms_installer.sh\
    && sh ldms_installer.sh


FROM ldms as final

COPY ./slurm/slurm.conf /etc/slurm/slurm.conf

COPY ./slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf

COPY ./slurm/cgroup.conf /etc/slurm/cgroup.conf

RUN set -x \
    && chown slurm:slurm /etc/slurm/slurmdbd.conf \
    && chmod 600 /etc/slurm/slurmdbd.conf \
    && chmod 644 /etc/slurm/slurm.conf

# A slurm plugin is activated : coming from LDMS
COPY ./slurm/plugstack.conf /etc/slurm/plugstack.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slurmdbd"]