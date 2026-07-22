FROM golang:1.26.4-alpine3.23 AS builder
WORKDIR /app
#
RUN apk -U upgrade
RUN apk -U add --no-cache ca-certificates git
RUN git clone https://github.com/t3chn0m4g3/h0neytr4p /app && \
    git -C /app checkout a542bd7a62f1033dde3f3b53c0b5873752a3e863
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/h0neytr4p .
#
FROM scratch
#
COPY --from=builder /out/h0neytr4p /opt/h0neytr4p/h0neytr4p
COPY --from=builder /app/traps /opt/h0neytr4p/traps
#
WORKDIR /opt/h0neytr4p
USER 2000:2000
CMD ["-cert=app.crt", "-key=app.key", "-log=log/log.json", "-catchall=false", "-payload=/data/h0neytr4p/payloads/", "-wildcard=true", "-traps=traps/"]
ENTRYPOINT ["./h0neytr4p"]
