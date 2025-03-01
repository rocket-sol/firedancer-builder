FROM ubuntu:jammy AS build

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
  && git submodule update

RUN cd firedancer && patch -p1 <<'EOF'
--- a/deps.sh
+++ b/deps.sh
@@ -279,7 +279,7 @@ check () {
 
   if [[ ! -x "$(command -v cargo)" ]]; then
     echo "[!] cargo is not in PATH"
-    source "$HOME/.cargo/env" || true
+    [[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
   fi
   if [[ ! -x "$(command -v cargo)" ]]; then
     if [[ "${FD_AUTO_INSTALL_PACKAGES:-}" == "1" ]]; then
EOF


RUN --mount=type=cache,target=$HOME/.cargo cd firedancer \
  && FD_AUTO_INSTALL_PACKAGES=1 ./deps.sh fetch check install

RUN --mount=type=cache,target=$HOME/.cargo . .cargo/env && cd firedancer &&  MACHINE=linux_gcc_x86_64 make -j $(nproc) fddev fdctl solana
RUN --mount=type=cache,target=$HOME/.cargo . .cargo/env && cd firedancer &&  MACHINE=linux_gcc_x86_64 make -j $(nproc) all

FROM ubuntu:jammy AS ubuntu
COPY --from=build /home/sol/firedancer/build/linux/gcc/x86_64/bin/ /opt/firedancer/bin/
ENTRYPOINT ["/opt/firedancer/bin/fdctl"]

FROM scratch
COPY --from=build /home/sol/firedancer/build/linux/gcc/x86_64/bin/ /
