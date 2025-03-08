FROM ubuntu:jammy AS source

RUN --mount=type=cache,dst=/var/lib/apt apt-get update && apt-get install -y \
  autoconf \
  automake \
  autopoint \
  bash \
  bison \
  build-essential \
  cmake \
  flex \
  gcc-multilib \
  gettext \
  git \
  lcov \
  libclang-dev \
  libgmp-dev \
  libudev-dev \
  llvm \
  pkgconf \
  protobuf-compiler \
  ;

RUN useradd --create-home sol

USER sol

WORKDIR /home/sol

ARG FIREDANCER_VERSION=v0.403.20113
RUN git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git \
  && cd firedancer \
  && git checkout $FIREDANCER_VERSION \
  && git submodule update --init

COPY patches patches
RUN cat patches/*.patch | patch --directory firedancer --forward --strip 1


FROM source AS build
RUN --mount=type=cache,target=$HOME/.cargo cd firedancer \
  && FD_AUTO_INSTALL_PACKAGES=1 ./deps.sh fetch check install

ARG JOBS_NUM=4
RUN --mount=type=cache,target=$HOME/.cargo . .cargo/env && cd firedancer &&  MACHINE=linux_gcc_x86_64 make -j $JOBS_NUM fddev fdctl solana
# Bug: err undeclared in src/choreo/forks/fd_forks.c, fixed in https://github.com/firedancer-io/firedancer/commit/99009cd869e1be8d5aa4bebed05555cc81719981
# RUN --mount=type=cache,target=$HOME/.cargo . .cargo/env && cd firedancer &&  MACHINE=linux_gcc_x86_64 make -j $JOBS_NUM all

FROM ubuntu:jammy AS ubuntu
COPY --from=build /home/sol/firedancer/build/linux/gcc/x86_64/bin/ /opt/firedancer/bin/
ENTRYPOINT ["/opt/firedancer/bin/fdctl"]

FROM scratch
COPY --from=build /home/sol/firedancer/build/linux/gcc/x86_64/bin/ /
