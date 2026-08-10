FROM quay.io/centos/centos:stream9

# Toolchain versions come from .tool-versions, shared with the application repo.
#
# OTP is built from source by mise/kerl instead of installed from
# rabbitmq/erlang-rpm: that package strips inets' httpd*/mod_* beams but still
# declares them in inets.app, so every release booting in embedded mode dies
# with {load_failed,[httpd,...]}.
ENV LANG=C.UTF-8 \
	RUST_ARCH=x86_64-unknown-linux-gnu \
	RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	MISE_DATA_DIR=/usr/local/share/mise \
	MISE_CONFIG_DIR=/usr/local/etc/mise \
	MISE_STATE_DIR=/usr/local/share/mise/state \
	MISE_CACHE_DIR=/var/cache/mise \
	MISE_TRUSTED_CONFIG_PATHS=/ \
	MISE_YES=1 \
	KERL_BUILD_DOCS=no \
	KERL_CONFIGURE_OPTIONS=--without-javac \
	PATH=/usr/local/share/mise/shims:/usr/local/cargo/bin:$PATH

# ncurses-devel, openssl-devel and zlib-devel are OTP link-time dependencies;
# wxGTK-devel is deliberately absent so configure omits wx and observer.
RUN dnf install -y epel-release; \
	dnf config-manager --set-enabled crb; \
	dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm; \
	dnf install -y \
		autoconf automake libtool make gcc gcc-c++ pkgconfig \
		openssl-devel ncurses-devel zlib-devel \
		perl tar xz unzip which findutils procps-ng \
		ansible openssh diffutils git git-lfs; \
	ln -sf /usr/bin/gcc /usr/bin/cc; \
	dnf clean all; \
	rm -rf /var/cache/yum

RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh; \
	mise --version

COPY .tool-versions ${MISE_CONFIG_DIR}/.tool-versions

# Pin the same versions globally so the shims resolve from any working
# directory, including checkouts whose own .tool-versions is absent.
RUN cd ${MISE_CONFIG_DIR}; \
	mise install; \
	mise use -g $(awk 'NF && $1 !~ /^#/ {printf "%s@%s ", $1, $2}' .tool-versions); \
	mise reshim; \
	mise ls --installed

RUN rustup component add rustfmt clippy; \
	rustup target add wasm32-unknown-unknown; \
	cargo install wasm-pack; \
	chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
	rm -rf $CARGO_HOME/registry $CARGO_HOME/git; \
	rm -rf $MISE_CACHE_DIR

CMD ["iex"]
