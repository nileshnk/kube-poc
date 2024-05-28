FROM golang:1.21.3-alpine AS build
WORKDIR /src

COPY . .

RUN go install

ARG TARGETARCH

# Build the application.

RUN go build -o /bin/server .

FROM alpine:3.20.0 AS final

# Install any runtime dependencies that are needed to run your application.
# Leverage a cache mount to /var/cache/apk/ to speed up subsequent builds.
# RUN --mount=type=cache,target=/var/cache/apk \
#     apk --update add \
#         ca-certificates \
#         tzdata \
#         && \
#         update-ca-certificates

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/

# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser
# USER appuser

# Copy the executable from the "build" stage.
COPY --from=build /bin/server /bin/

# Expose the port that the application listens on.
EXPOSE 5100

# What the container should run when it is started.
ENTRYPOINT [ "/bin/server" ]