FROM fedora:36

MAINTAINER Yousong Zhou <yszhou4tech@gmail.com>

RUN set -x \
	&& sed -i -e s/nodocs// /etc/dnf/dnf.conf \
	&& true

RUN set -x \
	&& dnf group install -y "C Development Tools and Libraries" \
	&& true

# python3-devel: ycmd build
# glibc-langpack-en: en_US.UTF-8 locale when running manpath
# hostname: for hostname command
# mariadb: mysql client
RUN set -x \
	&& dnf install -y \
		cmake \
		ctags \
		docker \
		file \
		git \
		git-email \
		glibc-langpack-en \
		hostname \
		iproute \
		iputils \
		jq \
		man-db \
		man-pages \
		mariadb \
		patch \
		procps \
		python3-devel \
		rsync \
		strace \
		sysstat \
		tcpdump \
		tmux \
		vim \
		wget \
		which \
		zsh \
	&& true

RUN set -x \
	&& dnf install -y \
		python3-pip \
	&& pip3 install https://github.com/yousong/polysh/archive/7fc055ef9075e5dbee4cc7abc020b89fccabfc67.zip \
	&& pip3 install \
		yq \
	&& true

# We use repo settings in the build machine for installing packages.  The built
# image is mostly to be used where aliyun mirrors is the faster accessible
RUN set -x \
	&& curl -o /etc/yum.repos.d/fedora.repo https://mirrors.aliyun.com/repo/fedora.repo \
	&& curl -o /etc/yum.repos.d/fedora-updates.repo https://mirrors.aliyun.com/repo/fedora-updates.repo \
	&& true

RUN set -x \
	&& adduser --shell /bin/zsh abc \
	&& echo "abc ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/abc \
	&& true

RUN set -x \
	&& mkdir -p /home/abc/.usr/n \
	&& curl -o n -L "https://raw.githubusercontent.com/tj/n/master/bin/n" \
	&& N_PREFIX=/home/abc/.usr bash n lts \
	&& rm -vf n \
	&& chown -R abc:abc /home/abc/.usr \
	&& true

ARG GOVERSION=go1.18.6
ARG GOURL=https://storage.googleapis.com/golang/$GOVERSION.linux-amd64.tar.gz
RUN set -x \
	&& mkdir -p /home/abc/.usr/go \
	&& cd /home/abc/.usr/go \
	&& curl -L "$GOURL" \
		| tar xzf - \
	&& chmod -R a-w go \
	&& mv go $GOVERSION \
	&& chown -R abc:abc /home/abc/.usr/go \
	&& true

RUN set -x \
	&& cd /home/abc \
	&& curl https://sh.rustup.rs -sSf \
		| sudo -u abc sh -s -- --no-modify-path --default-toolchain stable -y \
	&& sudo -u abc /home/abc/.cargo/bin/rustup component list --installed \
		| grep docs \
		| xargs sudo -u abc /home/abc/.cargo/bin/rustup component remove \
	&& sudo -u abc /home/abc/.cargo/bin/cargo install ripgrep \
	&& rm -rf /home/abc/.cargo/registry \
	&& true

ADD . /home/abc/git-repo/dconf
RUN set -x \
	&& cd /home/abc/git-repo/dconf \
	&& chown -R abc:abc /home/abc/git-repo \
	&& sudo -u abc \
		PATH=/home/abc/.usr/bin:$PATH \
		./dconf.sh config \
	&& cd /home/abc \
	&& rm -rf git-repo \
	&& sudo -iu abc PATH=/home/abc/.usr/go/$GOVERSION/bin:$PATH \
		vim +GoInstallBinaries +qa \
	&& /home/abc/go/bin/gopls version \
	&& rm -rf /home/abc/.cache/go-build \
	&& true

ADD ./hack/docker/run.sh /run.sh

CMD /run.sh entrypoint
