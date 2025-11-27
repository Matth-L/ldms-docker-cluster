###################################################
###################################################
###################################################
# Stage 1 (core): core package
###################################################
###################################################
###################################################

FROM almalinux:9@sha256:375aa0df1af54a6ad8f4dec9ec3e0df16feec385c4fb761ac5c5ccdd829d0170 AS package-installation

ARG PDSH_VERSION=2.35
ARG PMIX_VERSION=4.2.7
ARG OPENMPI_VERSION=5.0.8
ARG SLURM_VERSION=slurm-25-05-1-1

# ------------------------------------------------------------
# Base system setup
# ------------------------------------------------------------
RUN set -ex \
    && dnf makecache \
    && dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf clean all && rm -rf /var/cache/dnf

# ------------------------------------------------------------
# Package installation
# ------------------------------------------------------------

RUN set -ex \
    && dnf -y install \
        # Core utils
        wget \
        bzip2 \
        perl \
        psmisc \
        gnupg \
        bash-completion \
        vim-enhanced \
        man \
        procps \
        # Development / build tools
        gcc \
        gcc-c++ \
        make \
        git \
        dejagnu \
        # System / init & dbus
        systemd \
        dbus \
        dbus-daemon \
        dbus-devel \
        # Munge (auth for Slurm) and related
        munge \
        munge-devel \
        # Python
        python3 \
        python3-devel \
        python3-pip \
        # Database (MariaDB)
        mariadb-server \
        mariadb-devel \
        # Libraries used by LDMS/Slurm/OpenMPI/etc.
        http-parser-devel \
        json-c-devel \
        hwloc-devel \
        libevent-devel \
        # Docker
        docker \
        # Kafka libraries
        librdkafka \
        librdkafka-devel \
    && dnf clean all && rm -rf /var/cache/dnf


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

FROM package-installation AS tools


RUN set -x \
    && wget https://github.com/chaos/pdsh/releases/download/pdsh-${PDSH_VERSION}/pdsh-${PDSH_VERSION}.tar.gz \
    && tar -xzvf pdsh-${PDSH_VERSION}.tar.gz \
    && cd pdsh-${PDSH_VERSION} \
    && ./configure \
    && make \
    && make install

RUN set -x \
    && wget https://github.com/openpmix/openpmix/releases/download/v${PMIX_VERSION}/pmix-${PMIX_VERSION}.tar.gz \
    && tar -xzvf pmix-${PMIX_VERSION}.tar.gz \
    && cd pmix-${PMIX_VERSION} \
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
# SLURM INSTALLATION
###################################################
###################################################
###################################################

FROM tools AS slurm


RUN set -x \
    && git clone -b slurm-${SLURM_VERSION} --single-branch --depth=1 https://github.com/SchedMD/slurm.git \
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


FROM ldms AS final

COPY ./slurm/slurm.conf /etc/slurm/slurm.conf

COPY ./slurm/slurmdbd.conf /etc/slurm/slurmdbd.conf

COPY ./slurm/cgroup.conf /etc/slurm/cgroup.conf

COPY ./slurm/scripts /etc/slurm/scripts/

RUN set -x \
    && chown slurm:slurm /etc/slurm/slurmdbd.conf \
    && chmod 600 /etc/slurm/slurmdbd.conf \
    && chmod 644 /etc/slurm/slurm.conf

# A slurm plugin is activated : coming from LDMS
COPY ./slurm/plugstack.conf /etc/slurm/plugstack.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["slurmdbd"]