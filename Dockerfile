FROM quay.io/centos/centos:stream9

ENV LANG=C.UTF-8 \
	RUST_ARCH=x86_64-unknown-linux-gnu \
	RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	PATH=/usr/local/cargo/bin:$PATH \
	RUST_VERSION=1.96.0

RUN dnf install -y epel-release; \
	dnf config-manager --set-enabled crb; \
	dnf install -y https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm; \
	dnf module -y enable nodejs:24; \
	dnf module -y install nodejs:24/common; \
	rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key'; \
	printf '[modern-erlang]\nname=modern-erlang-el9\nbaseurl=https://yum1.rabbitmq.com/erlang/el/9/$basearch\nrepo_gpgcheck=1\nenabled=1\ngpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key\ngpgcheck=1\nsslverify=1\nsslcacert=/etc/pki/tls/certs/ca-bundle.crt\nmetadata_expire=300\npkg_gpgcheck=1\nautorefresh=1\ntype=rpm-md\n\n[modern-erlang-noarch]\nname=modern-erlang-el9-noarch\nbaseurl=https://yum1.rabbitmq.com/erlang/el/9/noarch\nrepo_gpgcheck=1\nenabled=1\ngpgkey=https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key\ngpgcheck=1\nsslverify=1\nsslcacert=/etc/pki/tls/certs/ca-bundle.crt\nmetadata_expire=300\npkg_gpgcheck=1\nautorefresh=1\ntype=rpm-md\n' \
		> /etc/yum.repos.d/rabbitmq-erlang.repo; \
	dnf install -y erlang automake gcc gcc-c++ pkgconfig openssl-devel ansible openssh diffutils git git-lfs npm; \
	ln -sf /usr/bin/gcc /usr/bin/cc; \
	curl -fSL -o elixir-src.tar.gz "https://github.com/elixir-lang/elixir/archive/v1.20.0.tar.gz"; \
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
