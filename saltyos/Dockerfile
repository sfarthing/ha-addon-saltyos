FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        qemu-system-x86 \
        qemu-utils \
        novnc \
        websockify \
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /saltyos

COPY saltyos.iso /saltyos/saltyos.iso
COPY disk.img /saltyos/disk.img.seed
COPY run.sh /run.sh
COPY index.html /usr/share/novnc/index.html

RUN chmod +x /run.sh

EXPOSE 5900
EXPOSE 6080

CMD ["/run.sh"]