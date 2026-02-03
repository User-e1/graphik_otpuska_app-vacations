# ЭТАП 1: Установка PHP зависимостей (Composer)
FROM composer:latest AS composer_stage
WORKDIR /app
COPY composer.json composer.lock ./
# Устанавливаем зависимости без запуска скриптов (так как кода еще нет в этом слое)
RUN composer install --no-scripts --no-autoloader --no-interaction --ignore-platform-reqs

# ЭТАП 2: Установка JS зависимостей и компиляция
FROM node:18-alpine AS node_stage
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# Компилируем ассеты
RUN npm run css-dev && npm run dev

# ЭТАП 3: Финальный образ (Apache + PHP 8.3)
FROM yiisoftware/yii2-php:8.3-apache
WORKDIR /app

# Устанавливаем зависимости для работы с PostgreSQL (если их нет в базовом образе)
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo pdo_postgres \
    && rm -rf /var/lib/apt/lists/*

# Копируем исходный код проекта
COPY . .

# Копируем вендоры из 1-го этапа
COPY --from=composer_stage /app/vendor ./vendor

# Копируем скомпилированные ассеты из 2-го этапа
# В Yii2 это обычно папка web/assets или web/dist — проверьте ваш путь!
COPY --from=node_stage /app/web ./web

# Достраиваем автозагрузку Composer (теперь, когда код скопирован)
RUN composer dump-autoloader --optimize

# Делаем скрипт запуска исполняемым
RUN chmod +x /app/refresh.sh
