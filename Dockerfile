FROM fedora:34

MAINTAINER Yousong Zhou <yszhou4tech@gmail.com>

# docker run --privileged --pid=host --network=host /bin/zsh
RUN set -x \
	&& sed -i -e s/nodocs// /etc/dnf/dnf.conf \
	&& dnf makecache \
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
		the_silver_searcher \
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

ARG GOVERSION=go1.17.6
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
	&& rm -rf /home/abc/.cache/go-build \
	&& true

ADD ./hack/docker/run.sh /run.sh

CMD /run.sh entrypoint
