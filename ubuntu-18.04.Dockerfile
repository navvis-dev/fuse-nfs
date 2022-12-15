# Just a reference for future me.
# Build should be run from the root of https://github.com/navvis-dev/fuse-nfs


# Build environment
FROM ubuntu:18.04 as BUILD
RUN apt update && \
    apt install --yes libfuse-dev libnfs11 libnfs-dev libtool m4 automake libnfs-dev xsltproc make libtool


COPY ./ /src
WORKDIR /src
RUN ./setup.sh && \
    ./configure && \
    make