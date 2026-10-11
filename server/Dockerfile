FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /caixinha-server .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /caixinha-server /caixinha-server
ENV CAIXINHA_DATA_DIR=/data CAIXINHA_ADDR=:8080
VOLUME /data
EXPOSE 8080
ENTRYPOINT ["/caixinha-server"]
