# Build environment
FROM ubuntu:jammy as BUILD
RUN apt update && \
    apt install --yes libfuse-dev libnfs13 libnfs-dev libtool m4 automake libnfs-dev xsltproc make libtool curl gcc libc-dev

# su-exec
RUN  set -ex; \
     \
     fetch_deps='curl gcc libc-dev'; \
     apt-get install -y --no-install-recommends $fetch_deps; \
     rm -rf /var/lib/apt/lists/*; \
     curl -o /usr/local/bin/su-exec.c https://raw.githubusercontent.com/navvis-dev/su-exec/master/su-exec.c; \
          \
     gcc -Wall /usr/local/bin/su-exec.c -o/usr/local/bin/su-exec; \
     chmod 0755 /usr/local/bin/su-exec

COPY ./ /src
WORKDIR /src
RUN ./setup.sh && \
    ./configure && \
    make




# Production image
FROM ubuntu:jammy
RUN apt update && \
    apt install --yes libnfs13 libfuse2 fuse && \
    apt clean autoclean && \
    apt autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY --from=BUILD /src/fuse/fuse-nfs /bin/fuse-nfs
COPY --from=BUILD /usr/local/bin/su-exec /bin/su-exec
COPY ./nfs-entrypoint.sh /
