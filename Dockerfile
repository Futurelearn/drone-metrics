FROM ruby:2.5.1-slim

COPY drone-metrics.rb /bin/drone-metrics

RUN gem install aws-sdk-cloudwatch

CMD ["/bin/drone-metrics"]
