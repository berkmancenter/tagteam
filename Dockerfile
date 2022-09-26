FROM ruby:2.4.1

# Debian issue in Docker
# https://superuser.com/a/1423685
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN apt-get clean && apt-get update && apt-get install -y --force-yes build-essential nodejs bash \
    chrpath libssl-dev libxft-dev libfreetype6 libfreetype6-dev libfontconfig1 \
    postgresql tzdata git default-jre \
    g++ qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base \
    gstreamer1.0-tools gstreamer1.0-x libfontconfig1-dev && \
    gem install sqlite3:1.3.4 mailcatcher --no-ri --no-rdoc --conservative

# Install PhantomJS
RUN curl -L "https://github.com/Medium/phantomjs/releases/download/v2.1.1/phantomjs-2.1.1-linux-x86_64.tar.bz2" --output phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
    tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/ && \
    ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin

RUN mkdir /app
WORKDIR /app

COPY . /app

CMD /bin/bash docker/start_dev.sh
