FROM quay.io/centos/centos:stream9

ENV LANG=C.UTF-8 \
	RUST_ARCH=x86_64-unknown-linux-gnu \
	RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	PATH=/usr/local/cargo/bin:$PATH \
	RUST_VERSION=1.91.1

RUN dnf install -y epel-release; \
	dnf config-manager --set-enabled crb; \
	dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm; \
	dnf module -y enable nodejs:24; \
	dnf module -y install nodejs:24/common; \
	dnf install -y erlang automake gcc pkgconfig openssl-devel ansible openssh diffutils git git-lfs npm; \
	curl -fSL -o elixir-src.tar.gz "https://github.com/elixir-lang/elixir/archive/v1.19.1.tar.gz"; \
	mkdir -p /usr/local/src/elixir; \
	tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz; \
	rm elixir-src.tar.gz; \
	cd /usr/local/src/elixir; \
	make install clean; \
	find /usr/local/src/elixir/ -type f -not -regex "/usr/local/src/elixir/lib/[^\/]*/lib.*" -exec rm -rf {} +; \
	find /usr/local/src/elixir/ -type d -depth -empty -delete; \
	curl -fSL -o rustup-init "https://static.rust-lang.org/rustup/archive/1.28.2/${RUST_ARCH}/rustup-init"; \
	chmod +x rustup-init; \
	./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${RUST_ARCH}; \
	rm rustup-init; \
	chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
	rustup --version; \
	cargo --version; \
	rustc --version; \
	rustup component add rustfmt clippy; \
	rustup target add wasm32-unknown-unknown; \
	cargo install wasm-pack; \
	dnf clean all; \
	rm -rf /var/cache/yum

CMD ["iex"]
