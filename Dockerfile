FROM php:8.1-apache

RUN a2enmod ssl && a2enmod rewrite
RUN mkdir -p /etc/apache2/ssl
#RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
ENV PHP_MEMORY_LIMIT=512M
#install some base extensions
RUN apt-get update && \
    apt-get install -y \
        curl \
        zlib1g-dev \
        zip \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libmemcached-dev && \
    docker-php-ext-install zip && \
    docker-php-ext-configure gd --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd && \
    docker-php-ext-install opcache && \
    docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli && \
    docker-php-ext-install pdo &&  \
    docker-php-ext-install pdo_mysql

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini


RUN pecl install memcached-3.1.5 && \
    docker-php-ext-enable memcached

COPY docker/apache/ssl/ssl.crt /etc/apache2/ssl/
COPY docker/apache/ssl/ssl.key /etc/apache2/ssl/
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2ensite 000-default.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

WORKDIR "/var/www"

COPY composer.json /var/www/composer.json

RUN composer install

# Install Drush
RUN composer require drush/drush && \
    composer update

# Install drupal-check
RUN composer require mglaman/drupal-check --dev

EXPOSE 80
EXPOSE 443
