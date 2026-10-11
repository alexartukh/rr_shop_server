-- =====================================================================
--  Инициализация БД интернет-магазина (PostgreSQL)
--  Таблица users совместима с Devise + devise-jwt.
--  Запуск:  psql -d shop_api_development -f db/init.sql
--  Скрипт можно запускать повторно: он удаляет и заново создаёт таблицы.
-- =====================================================================

BEGIN;

-- pgcrypto: bcrypt-хэши паролей тестовых пользователей (crypt/gen_salt)
-- и генерация jti для JWT (gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS orders_description;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS users;

-- ---------------------------------------------------------------------
-- 1. Пользователи
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id              BIGSERIAL     PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    email           VARCHAR(255)  NOT NULL,
    encrypted_password VARCHAR(255) NOT NULL DEFAULT '', -- bcrypt-хэш пароля (имя колонки ждёт Devise)
    role            VARCHAR(10)   NOT NULL DEFAULT 'USER'
                    CHECK (role IN ('ADMIN', 'USER')),
    -- Идентификатор для отзыва JWT-токенов (devise-jwt, стратегия JTIMatcher).
    -- При выходе он меняется, и все выданные ранее токены перестают действовать.
    jti             VARCHAR(255)  NOT NULL DEFAULT gen_random_uuid()::text,
    created_at      TIMESTAMP(6)  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP(6)  NOT NULL DEFAULT now()
);

-- email уникален без учёта регистра
CREATE UNIQUE INDEX index_users_on_lower_email ON users (LOWER(email));
CREATE UNIQUE INDEX index_users_on_jti ON users (jti);

-- ---------------------------------------------------------------------
-- 2. Товары
-- ---------------------------------------------------------------------
CREATE TABLE items (
    id          BIGSERIAL      PRIMARY KEY,
    name        VARCHAR(255)   NOT NULL,
    description TEXT,
    price       NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    created_at  TIMESTAMP(6)   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(6)   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- 3. Заказы
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    id          BIGSERIAL      PRIMARY KEY,
    user_id     BIGINT         NOT NULL
                REFERENCES users (id) ON DELETE RESTRICT,
    amount      NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
    created_at  TIMESTAMP(6)   NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(6)   NOT NULL DEFAULT now()
);

CREATE INDEX index_orders_on_user_id ON orders (user_id);

-- ---------------------------------------------------------------------
-- 4. Состав заказа (позиции)
-- ---------------------------------------------------------------------
CREATE TABLE orders_description (
    id          BIGSERIAL     PRIMARY KEY,
    order_id    BIGINT        NOT NULL
                REFERENCES orders (id) ON DELETE CASCADE,
    item_id     BIGINT        NOT NULL
                REFERENCES items (id) ON DELETE RESTRICT,
    quantity    INTEGER       NOT NULL CHECK (quantity > 0),
    created_at  TIMESTAMP(6)  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(6)  NOT NULL DEFAULT now(),
    UNIQUE (order_id, item_id)                          -- один товар в заказе одной строкой
);

CREATE INDEX index_orders_description_on_item_id ON orders_description (item_id);

-- =====================================================================
--  Тестовые данные
-- =====================================================================

INSERT INTO users (first_name, last_name, email, encrypted_password, role) VALUES
    ('Alex', 'Artukh', 'alex@example.com', crypt('123', gen_salt('bf', 12)), 'ADMIN'),
    ('Test',  'Test',  'test@example.com',  crypt('123',  gen_salt('bf', 12)), 'USER'),
    ('Denis', 'Bushtruk', 'denis@example.com',  crypt('123',  gen_salt('bf', 12)), 'USER')
;

INSERT INTO items (name, description, price) VALUES
    ('Raspberry Pi 5', 'Powered by a 2.4 GHz quad-core Arm Cortex-A76 CPU ', 64.95),
    ('Raspberry Pi Camera Module 3', 'Raspberry Pi’s classic compact camera', 29.95),
    ('Raspberry Pi 5 Bumper Case', 'The Raspberry Pi Bumper is a one-piece silicone cover that snaps securely around the edges and underside of the board, guarding it against bumps, scratches, and slipping—without adding unnecessary bulk.', 3.95),
    ('Raspberry Pi 45W USB-C Power Supply', 'When your project needs more juice, step up to the Raspberry Pi 45W USB-C Power Supply.', 14.20),
    ('Raspberry Pi SSD', 'Boost your Raspberry Pi 5 to desktop-class performance.', 43.00),
    ('Raspberry Pi 5 Active Cooler', 'The Raspberry Pi Active Cooler is the official clip-on cooling upgrade built specifically for the Raspberry Pi 5.', 7.00),
    ('Raspberry Pi Display Cable Standard - Mini', 'Hook up your display with confidence.', 2.00)
;

COMMIT;
