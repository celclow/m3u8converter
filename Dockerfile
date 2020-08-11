FROM    jrottenberg/ffmpeg

WORKDIR /tmp/workdir

ADD     m3u8converter.sh /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends wget && \
        apt-get autoremove -y && \
        apt-get clean -y

ENTRYPOINT      ["./m3u8converter.sh"]
