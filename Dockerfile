FROM golang:alpine as builder

ENV PATH /go/bin:/usr/local/go/bin:$PATH
ENV GOPATH /go

RUN	apk add --no-cache \
	ca-certificates

COPY . /go/src/github.com/Azure-Samples/openhack-team-cli

RUN set -x \
	&& apk add --no-cache --virtual .build-deps \
		git \
		gcc \
		libc-dev \
		libgcc \
        make \
	&& cd /go/src/github.com/Azure-Samples/openhack-team-cli \
	&& make build \ 
	&& apk del .build-deps \
    && cp bin/oh /usr/bin/oh \
	&& rm -rf /go \
	&& echo "Build complete."

FROM scratch

COPY --from=builder /usr/bin/oh /usr/bin/oh
COPY --from=builder /etc/ssl/certs/ /etc/ssl/certs

ENTRYPOINT [ "/usr/bin/oh" ]
CMD [ "--help" ]