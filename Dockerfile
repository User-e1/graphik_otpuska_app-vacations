# ЭТАП 1: Установка PHP зависимостей (Composer)
FROM composer:latest AS composer_stage
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader

# ЭТАП 2: Установка JS зависимостей и компиляция (Node.js)
FROM node:18-alpine AS node_stage
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Компилируем ассеты (аналог npm run css-dev && npm run dev)
RUN npm run css-dev && npm run dev

# ЭТАП 3: Финальный образ (PHP-FPM / Apache)
FROM php:8.2-fpm-alpine
WORKDIR /var/www/html
# Копируем всё из проекта
COPY . .
# Копируем вендоры и скомпилированные ассеты из предыдущих этапов
COPY --from=composer_stage /app/vendor ./vendor
COPY --from=node_stage /app/public ./public 
# (путь /public может отличаться в зависимости от структуры вашего Laravel/Symfony проекта)

RUN php artisan optimize  # Для Laravel, если актуально
