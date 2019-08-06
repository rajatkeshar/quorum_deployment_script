# Build
FROM alpine:3.9

RUN apk add --no-cache make gcc musl-dev linux-headers git

RUN apk add --update \
	openssl \
	bash \
    curl \
	jq \
	netcat-openbsd \
    logrotate \
    openjdk8-jre-base=8.212.04-r0 \
	#openjdk8=8.212.04-r0 \
 	&& rm /var/cache/apk/* \
 	&& echo "securerandom.source=file:/dev/urandom" >> /usr/lib/jvm/default-jvm/jre/lib/security/java.security

RUN wget -q https://github.com/jpmorganchase/tessera/releases/download/tessera-0.6/tessera-app-0.6-app.jar
RUN mkdir /root/tessera
RUN mv ./tessera-app-0.6-app.jar /root/tessera/tessera.jar
RUN echo "export  TESSERA_JAR=/root/tessera/tessera.jar" >> ~/.profile
RUN echo "export TESSERA_JAR=/root/tessera/tessera.jar" >> ~/.bashrc
RUN export TESSERA_JAR="/root/tessera/tessera.jar"

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GOLANG_VERSION 1.9.7

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		bash \
		gcc \
		musl-dev \
		openssl \
		go \
	; \
	export \
	# set GOROOT_BOOTSTRAP such that we can actually build Go
	GOROOT_BOOTSTRAP="$(go env GOROOT)" \
	# ... and set "cross-building" related vars to the installed system's values so that we create a build targeting the proper arch
	# (for example, if our build host is GOARCH=amd64, but our build env/image is GOARCH=386, our build needs GOARCH=386)
	GOOS="$(go env GOOS)" \
	GOARCH="$(go env GOARCH)" \
	GOHOSTOS="$(go env GOHOSTOS)" \
	GOHOSTARCH="$(go env GOHOSTARCH)" \
	; \
	# also explicitly set GO386 and GOARM if appropriate
	# https://github.com/docker-library/golang/issues/184
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		armhf) export GOARM='6' ;; \
		x86) export GO386='387' ;; \
	esac; \
	\
	wget -O go.tgz "https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz"; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	cd /usr/local/go/src; \
	./make.bash; \
	\
	rm -rf \
	# https://github.com/golang/go/blob/0b30cf534a03618162d3015c8705dd2231e34703/src/cmd/dist/buildtool.go#L121-L125
	/usr/local/go/pkg/bootstrap \
	# https://golang.org/cl/82095
	# https://github.com/golang/build/blob/e3fe1605c30f6a3fd136b561569933312ede8782/cmd/release/releaselet.go#L56
	/usr/local/go/pkg/obj \
	; \
	apk del .build-deps; \
	\
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY quorum ./quorum
RUN cd /quorum && go get github.com/urfave/cli && \
	make geth bootnode && \
	cp build/bin/geth /usr/local/bin/ && \
	cp build/bin/bootnode /usr/local/bin/

COPY . ./deployment_script
RUN rm -rf -r quorum/ /deployment_script/quorum
WORKDIR deployment_script
CMD ["./setup.sh"]