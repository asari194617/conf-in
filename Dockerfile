FROM ruby:1.9.3-p551

RUN echo "deb http://archive.debian.org/debian/ jessie main" > /etc/apt/sources.list \
    && apt-get update -o Acquire::Check-Valid-Until=false -qq \
    && apt-get install -y --force-yes build-essential libmysqlclient-dev nodejs

WORKDIR /usr/src/app

COPY Gemfile* ./
RUN bundle install

COPY . .

CMD ["rails", "server", "-b", "0.0.0.0"]
