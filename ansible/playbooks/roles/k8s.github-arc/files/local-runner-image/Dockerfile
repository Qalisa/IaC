# Build argo-watcher
FROM golang:1.22.4 as builder
WORKDIR /usr/src/app
RUN git clone https://github.com/shini4i/argo-watcher.git .
RUN make install-deps docs mocks
RUN go mod tidy
WORKDIR /usr/src/app/cmd/argo-watcher
RUN go build -o /argo-watcher

FROM ghcr.io/actions/actions-runner:latest

# Copy the binary from the builder stage
COPY --from=builder /argo-watcher /usr/local/bin

# modify actions runner binaries to allow custom cache server implementation
RUN sed -i 's/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x43\x00\x41\x00\x43\x00\x48\x00\x45\x00\x5F\x00\x55\x00\x52\x00\x4C\x00/\x41\x00\x43\x00\x54\x00\x49\x00\x4F\x00\x4E\x00\x53\x00\x5F\x00\x43\x00\x41\x00\x43\x00\x48\x00\x45\x00\x5F\x00\x4F\x00\x52\x00\x4C\x00/g' /home/runner/bin/Runner.Worker.dll

#
USER root
COPY argo-watcher-client.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/argo-watcher-client.sh
USER runner