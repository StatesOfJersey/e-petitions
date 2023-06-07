FROM ruby:3.0

ARG VERSION=0.8.2

RUN gem install mailcatcher -v $VERSION

EXPOSE 1025 1080

ENTRYPOINT ["mailcatcher", "--foreground"]
CMD ["--ip", "0.0.0.0"]
