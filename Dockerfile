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
RUN set -x \
	&& dnf install -y \
		cmake \
		ctags \
		docker \
		git \
		glibc-langpack-en \
		hostname \
		iproute \
		iputils \
		man-db \
		man-pages \
		procps \
		python3-devel \
		strace \
		tcpdump \
		tmux \
		vim \
		wget \
		which \
		zsh \
	&& true

RUN set -x \
	&& adduser --shell /bin/zsh abc \
	&& echo "abc ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/abc \
	&& true

ARG GOVERSION=go1.16.7
ARG GOURL=https://storage.googleapis.com/golang/$GOVERSION.linux-amd64.tar.gz
RUN set -x \
	&& mkdir -p /home/abc/.usr/go \
	&& cd /home/abc/.usr/go \
	&& curl -L "$GOURL" \
		| tar xzf - \
	&& chmod -R a-w go \
	&& mv go $GOVERSION \
	&& chown -R abc:abc /home/abc/.usr \
	&& true

ADD . /home/abc/git-repo/dconf
RUN set -x \
	&& cd /home/abc/git-repo/dconf \
	&& chown -R abc:abc /home/abc/git-repo \
	&& sudo -u abc ./dconf.sh config \
	&& cd /home/abc \
	&& rm -rf git-repo \
	&& sudo -iu abc PATH=/home/abc/.usr/go/$GOVERSION/bin:$PATH \
		vim +GoInstallBinaries +qa \
	&& rm -rf /home/abc/.cache/go-build \
	&& true

ADD ./hack/docker/run.sh /run.sh

CMD /run.sh entrypoint
