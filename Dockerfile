FROM ubuntu:14.04

MAINTAINER hideakihal

# install basic package
ADD sources.list /etc/apt/sources.list
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
    openssh-server \
    supervisor \
    build-essential \
    curl \
    unzip \
    git-core \
    ruby1.9.1-dev \
    ruby-bundler \
    libxslt-dev \
    libxml2-dev \
    libpq-dev \
    libsqlite3-dev \
    gcc \
    g++ \
    make && \
    curl -sL https://deb.nodesource.com/setup | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

# root user
RUN echo 'root:root' | chpasswd

# install sshd
RUN mkdir -p /root/.ssh /var/run/sshd
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# hubot user
RUN useradd -m -s /bin/bash hubot 
RUN echo 'hubot:hubot' | chpasswd
RUN echo 'hubot ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/hubot
ENV HOME /home/hubot

# install Kandan
USER hubot
WORKDIR /home/hubot
RUN wget https://github.com/kandanapp/kandan/archive/v1.2.tar.gz
RUN tar xvf v1.2.tar.gz
RUN mv kandan-1.2/ kandan
RUN echo 'gem: --no-rdoc --no-ri' >> /home/hubot/.gemrc
WORKDIR /home/hubot/kandan
RUN sudo gem install execjs
RUN sudo sed -ri "s/gem 'pg'/gem 'sqlite3'/g" /home/hubot/kandan/Gemfile
RUN bundle install --without development test
ADD kandan/database.yml /home/hubot/kandan/config/database.yml
RUN RAILS_ENV=production bundle exec rake db:create db:migrate kandan:bootstrap
RUN sed -ri 's/config.serve_static_assets = false/config.serve_static_assets = true/g' \
    /home/hubot/kandan/config/environments/production.rb
RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN RAILS_ENV=production bundle exec rake kandan:boot_hubot
RUN RAILS_ENV=production bundle exec rake kandan:hubot_access_key | awk '{print $6}' > hubot-key

# install Hubot
WORKDIR /home/hubot
RUN wget https://github.com/github/hubot/archive/v2.4.7.zip
RUN unzip v2.4.7.zip
WORKDIR /home/hubot/hubot-2.4.7
RUN sudo npm install -g mime@1.2.4 qs@0.4.2
RUN npm install
RUN make package
WORKDIR /home/hubot/hubot-2.4.7/hubot
RUN git clone https://github.com/kandanapp/hubot-kandan.git node_modules/hubot-kandan
RUN npm install faye
RUN npm install ntwitter
ADD hubot/package.json /home/hubot/hubot-2.4.7/hubot/package.json
ADD hubot/hubot-scripts.json /home/hubot/hubot-2.4.7/hubot/hubot-scripts.json
RUN sed -ri 's/"version":     "1.0",/"version":     "1.0.0",/g' node_modules/hubot-kandan/package.json
USER root
ADD hubot/hubot.sh /etc/profile.d/hubot.sh
RUN awk '{print "export HUBOT_KANDAN_TOKEN="$0}' /home/hubot/kandan/hubot-key >> /etc/profile.d/hubot.sh 

# add supervisor config file 
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d
ADD sshd.conf /etc/supervisor/conf.d/sshd.conf
ADD kandan/kandan.conf /etc/supervisor/conf.d/kandan.conf
ADD hubot/hubot.conf /etc/supervisor/conf.d/hubot.conf
RUN awk '{print " HUBOT_KANDAN_TOKEN="$0}' /home/hubot/kandan/hubot-key >> /etc/supervisor/conf.d/hubot.conf 

# expose ports
EXPOSE 22 3000

# define default command
CMD supervisord -n
