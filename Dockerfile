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

RUN cd firedancer && patch -p1 <<'EOF'
--- a/deps.sh
+++ b/deps.sh
@@ -85,7 +85,7 @@ checkout_repo () {
     echo "[~] Skipping $1 fetch as \"$PREFIX/git/$1\" already exists"
   elif [[ -z "$3" ]]; then
     echo "[+] Cloning $1 from $2"
-    git -c advice.detachedHead=false clone "$2" "$PREFIX/git/$1" && cd "$PREFIX/git/$1" && git reset --hard "$4"
+    git -c advice.detachedHead=false clone "$2" "$PREFIX/git/$1" && git -C "$PREFIX/git/$1" reset --hard "$4"
     echo
   else
     echo "[+] Cloning $1 from $2"
EOF

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
