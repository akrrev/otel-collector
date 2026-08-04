FROM alpine:3.22 AS certs
RUN apk --update add ca-certificates

FROM golang:1.26.0 AS build-stage
WORKDIR /build

COPY ./manifest.yaml builder-config.yaml

RUN --mount=type=cache,target=/root/.cache/go-build GO111MODULE=on go install go.opentelemetry.io/collector/cmd/builder@v0.153.0
RUN --mount=type=cache,target=/root/.cache/go-build builder --config builder-config.yaml

FROM gcr.io/distroless/base:latest

ARG USER_UID=10001
USER ${USER_UID}

# This is only required if the config should be baked-in to the collector.
# COPY ./collector-config.yaml /otelcol/collector-config.yaml
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --chmod=755 --from=build-stage /build/otelcol-akrrev-minimal /otelcol

ENTRYPOINT ["/otelcol/otelcol-akrrev-minimal"]
# CMD ["--config", "/otelcol/collector-config.yaml"]

EXPOSE 4317 4318 12001
