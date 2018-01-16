FROM ruby:2.3.6

# ffmpeg from static build
RUN apt-get update && \
    apt-get install -y xz-utils && \
    cd /root && \
    wget -q https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-64bit-static.tar.xz && \
    tar xvJf ffmpeg-git-64bit-static.tar.xz && \
    mv ffmpeg-git-*-64bit-static/ffmpeg ffmpeg-git-*-64bit-static/ffprobe /usr/local/bin && \
    apt-get clean && \
    rm -rf /root/ffmpeg* /var/lib/apt/lists/* /var/cache/apt/*

# phantomjs
RUN apt-get update && \
    apt-get install -y libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev && \
    cd /root && \
    wget --local-encoding=utf-8 -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    mv phantomjs-*/bin/phantomjs /usr/local/bin && \
    apt-get clean && \
    rm -rf /root/phantomjs* /var/lib/apt/lists/* /var/cache/apt/*

# pre-bundle dependencies
WORKDIR /home
ENV HOME=/home
ADD Gemfile ./
ADD Gemfile.lock ./
RUN bundle install

ENTRYPOINT [ "/bin/bash" ]
