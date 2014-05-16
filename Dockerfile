FROM phusion/baseimage:0.9.9
MAINTAINER MATSHI Shinsuke <poppen.jp@gmail.com>

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y build-essential wget curl git zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev

# Install REE
RUN cd /usr/src \
 && wget http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2012.02.tar.gz \
 && tar xzf ruby-enterprise-1.8.7-2012.02.tar.gz \
 && cd /usr/src/ruby-enterprise-1.8.7-2012.02/source \
 && wget 'https://github.com/wayneeseguin/rvm/raw/master/patches/ree/1.8.7/tcmalloc.patch' \
 && wget 'https://github.com/wayneeseguin/rvm/raw/master/patches/ree/1.8.7/stdout-rouge-fix.patch' \
 && patch -p1 < tcmalloc.patch \
 && patch -p1 < stdout-rouge-fix.patch \
 && cd .. \
 && ./installer --auto /usr/local --dont-install-useful-gems \
 && echo "RUBY_HEAP_MIN_SLOTS=600000\nRUBY_HEAP_SLOTS_INCREMENT=10000\nRUBY_HEAP_SLOTS_GROWTH_FACTOR=1.8\nRUBY_GC_MALLOC_LIMIT=59000000\nRUBY_HEAP_FREE_MIN=100000" >> /etc/environment

# Install Passenger
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 \
 && apt-get -y install apt-transport-https ca-certificates \
 && echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger precise main" > /etc/apt/sources.list.d/passenger.list \
 && apt-get update \
 && apt-get -y install nginx-extras passenger \
 && sed -i -re "s!#\s*(passenger_root)\s*(.*)!\1 \2!" /etc/nginx/nginx.conf \
 && sed -i -re "s!#\s*(passenger_ruby)\s*/usr/bin/ruby;!\1 /usr/local/bin/ruby;!" /etc/nginx/nginx.conf \
 && echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run

ONBUILD ADD /www /www
ONBUILD ADD site.conf /etc/nginx/etc/nginx/sites-available/default

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/* /usr/src/*
