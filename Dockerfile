# ЭТАП 1: PHP зависимости
FROM composer:latest AS composer_stage
WORKDIR /app
COPY composer.json composer.lock ./
# Устанавливаем всё, включая автозагрузчик, на этом этапе
RUN composer install --no-scripts --no-interaction --ignore-platform-reqs

# ЭТАП 2: JS зависимости


FROM node:18-alpine AS node_stage
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Важно: запускаем сборку, которая генерирует файлы
RUN npm run dev 

# ЭТАП 3: Финальный образ
FROM yiisoftware/yii2-php:8.3-apache

# Настройка окружения
ENV APACHE_DOCUMENT_ROOT /app/web
WORKDIR /app

# Установка расширений Postgres
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Копируем всё содержимое проекта
COPY . .

# Копируем уже готовые vendor и web из предыдущих этапов
# Это исключает необходимость запуска composer dump-autoloader в финальном слое
COPY --from=composer_stage /app/vendor ./vendor
COPY --from=node_stage /app/web ./web

# Права на папки и скрипт
RUN chmod +x /app/refresh.sh && \
    mkdir -p runtime web/assets && \
    chmod -R 777 runtime web/assets
    
RUN sed -i 's|/var/www/html|/app/web|g' /etc/apache2/sites-available/000-default.conf

