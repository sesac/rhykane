FROM ruby:3.2.0 AS rhykane

ARG BUNDLE_GITHUB__COM
ENV BUNDLE_GITHUB__COM=$BUNDLE_GITHUB__COM

RUN apt-get update && apt-get install -y \
    libaio1 \
    locales \
    && locale-gen en_US.UTF-8 \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive tzdata \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
    && chmod +x /usr/local/bin/dumb-init \
    && gem install bundler

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

WORKDIR /var/app

COPY Gemfile* *.gemspec /var/app/
COPY lib/rhykane/version.rb /var/app/lib/rhykane/

RUN bundle install --jobs 20

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]


FROM alpine AS chamber

ARG CHAMBER_VERSION=v2.11.0

RUN apk --no-cache add curl \
    && curl -Ls https://github.com/segmentio/chamber/releases/download/$CHAMBER_VERSION/chamber-$CHAMBER_VERSION-linux-amd64 -o "/bin/chamber" \
    && chmod +x "/bin/chamber"

ENTRYPOINT ["chamber"]
