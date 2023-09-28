FROM debian:bullseye as verilog_builder

ENV IVERILOG_VERSION=v12_0

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y autoconf gperf make gcc g++ bison flex git && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --branch=${IVERILOG_VERSION} https://github.com/steveicarus/iverilog && \
    cd iverilog && \
    bash autoconf.sh && \
    ./configure && \
    make && \
    make install && \
    cd && \
    rm -rf iverilog

RUN ls /usr/local/lib/

FROM debian:bullseye as verible_builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y wget curl jq && \
    rm -rf /var/lib/apt/lists/*

RUN wget -qO- \
    $(curl -s https://api.github.com/repos/chipsalliance/verible/releases |\ 
    jq -r '.[0].assets[] |\ 
    select(.name |\
    test("focal-x86_64.tar.gz")) |\
    .browser_download_url ') |\
    tar xvz -C /tmp

RUN mv $(find /tmp -type f | grep "verible" | grep "/bin/") /usr/local/bin

FROM debian:bullseye

COPY --from=verilog_builder /usr/local/bin/iverilog /usr/local/bin
COPY --from=verilog_builder /usr/local/bin/iverilog-vpi /usr/local/bin
COPY --from=verilog_builder /usr/local/bin/vvp /usr/local/bin
COPY --from=verilog_builder /usr/local/lib/ivl /usr/local/lib/ivl

COPY --from=verible_builder /usr/local/bin/git-verible-verilog-format.sh /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-patch-tool /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-transform-interactive.sh /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-diff /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-format /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-format-changed-lines-interactive.sh /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-kythe-extractor /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-kythe-kzip-writer /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-lint /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-ls /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-obfuscate /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-preprocessor /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-project /usr/local/bin
COPY --from=verible_builder /usr/local/bin/verible-verilog-syntax /usr/local/bin

RUN apt update && \
    apt install -y make gcc g++ git gtkwave && \
    rm -rf /var/lib/apt/lists/*