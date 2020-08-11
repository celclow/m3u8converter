FROM    jrottenberg/ffmpeg

WORKDIR /tmp/m3u8c/work

ADD     m3u8converter.sh /tmp/m3u8c

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends wget && \
        apt-get autoremove -y && \
        apt-get clean -y

ENTRYPOINT      ["/tmp/m3u8c/m3u8converter.sh"]
