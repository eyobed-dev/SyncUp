FROM alpine:3.20

ARG PB_VERSION=0.24.3

RUN apk add --no-cache unzip wget ca-certificates

WORKDIR /pb

RUN wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip" -O pb.zip \
  && unzip pb.zip \
  && chmod +x /pb/pocketbase \
  && rm -f pb.zip

EXPOSE 8090

ENTRYPOINT ["sh", "-c", "if [ -n \"${POCKETBASE_SUPERUSER_EMAIL:-}\" ] && [ -n \"${POCKETBASE_SUPERUSER_PASSWORD:-}\" ]; then /pb/pocketbase --dir=/pb_data superuser upsert \"${POCKETBASE_SUPERUSER_EMAIL}\" \"${POCKETBASE_SUPERUSER_PASSWORD}\"; fi; exec /pb/pocketbase serve --http=0.0.0.0:8090 --dir=/pb_data"]

