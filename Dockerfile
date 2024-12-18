FROM ruby:3.1.3

# Install Node.js and Yarn (required for Shakapacker)
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y nodejs yarn build-essential libpq-dev && \
    apt-get clean
    
# Set environment variables for the app
ENV RAILS_ENV=development \
    NODE_ENV=development    

COPY . /app

COPY entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/entrypoint.sh

WORKDIR /app

RUN bundle install

RUN yarn install --ignore-engines

EXPOSE 3000 3035

ENTRYPOINT ["entrypoint.sh"]

CMD ["sh", "-c", "bin/rails server -b 0.0.0.0 -p 3000 & bin/shakapacker-dev-server"]
