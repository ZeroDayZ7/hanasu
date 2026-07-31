FROM alpine:3.20

RUN apk add --no-cache \
    curl \
    tar \
    bzip2 \
    libgomp \
    libstdc++ \
    bash

WORKDIR /app

# Pobranie binarki Sherpa-ONNX dla Linux x86_64
RUN curl -SL https://github.com/k2-fsa/sherpa-onnx/releases/latest/download/sherpa-onnx-linux-x64.tar.bz2 | tar -xj \
    && mv sherpa-onnx-linux-x64 sherpa

ENV PATH="/app/sherpa/bin:${PATH}"

CMD ["tail", "-f", "/dev/null"]
