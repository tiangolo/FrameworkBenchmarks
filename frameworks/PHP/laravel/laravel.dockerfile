FROM ubuntu:16.04

RUN apt update -yqq && apt install -yqq software-properties-common
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update -yqq
RUN apt install -yqq nginx git unzip php7.2 php7.2-common php7.2-cli php7.2-fpm php7.2-mysql php7.2-mbstring php7.2-xml

COPY deploy/conf/* /etc/php/7.2/fpm/

RUN mkdir /composer
WORKDIR /composer

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"

ENV PATH /composer:${PATH}

ADD ./ /laravel
WORKDIR /laravel

RUN mkdir -p /laravel/bootstrap/cache
RUN mkdir -p /laravel/storage/framework/sessions
RUN mkdir -p /laravel/storage/framework/views
RUN mkdir -p /laravel/storage/framework/cache

RUN chmod -R 777 /laravel

RUN composer.phar install --no-progress

RUN php artisan config:cache
RUN php artisan route:cache

RUN chmod -R 777 /laravel

CMD service php7.2-fpm start && \
    nginx -c /laravel/deploy/nginx.conf -g "daemon off;"
