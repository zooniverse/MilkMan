FROM ruby:2.2.10

WORKDIR /src/

ADD Gemfile /src/
ADD Gemfile.lock /src/

RUN bundle install

ADD . /src/

CMD [ "rails", "server", "-p", "80" ]
