FROM ruby:2.4.1

# Debian issue in Docker
# https://superuser.com/a/1423685
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y build-essential nodejs bash \
    postgresql tzdata git sqlite3 libsqlite3-dev default-jre \
    g++ qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base \
    gstreamer1.0-tools gstreamer1.0-x && \
    gem install mailcatcher --no-ri --no-rdoc

RUN mkdir /app
WORKDIR /app

COPY . .
COPY docker/start_dev.sh .
# capybara-webkit needs it
ENV PATH /usr/lib/qt5/bin:$PATH
RUN bundle install

CMD ["/bin/bash", "start_dev.sh"]
