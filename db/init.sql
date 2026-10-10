-- =====================================================================
--  Инициализация БД интернет-магазина (PostgreSQL)
--  Запуск:  psql -d shop_api_development -f db/init.sql
--  Скрипт можно запускать повторно: он удаляет и заново создаёт таблицы.
-- =====================================================================

BEGIN;

-- Расширение для bcrypt-хэшей паролей тестовых пользователей
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
    password_digest VARCHAR(255)  NOT NULL,             -- bcrypt-хэш, не сам пароль
    role            VARCHAR(10)   NOT NULL DEFAULT 'USER'
                    CHECK (role IN ('ADMIN', 'USER')),
    created_at      TIMESTAMP(6)  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP(6)  NOT NULL DEFAULT now()
);

-- email уникален без учёта регистра
CREATE UNIQUE INDEX index_users_on_lower_email ON users (LOWER(email));

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
--  Пароли: admin@shop.test / admin123,  user@shop.test / user123
-- =====================================================================

INSERT INTO users (first_name, last_name, email, password_digest, role) VALUES
    ('Admin', 'Adminov', 'admin@shop.test', crypt('admin123', gen_salt('bf', 12)), 'ADMIN'),
    ('Ivan',  'Petrov',  'user@shop.test',  crypt('user123',  gen_salt('bf', 12)), 'USER');

INSERT INTO items (name, description, price) VALUES
    ('Кофе Арабика 1 кг',      'Зерновой кофе, средняя обжарка',          24.90),
    ('Чай зелёный Сенча',      'Японский зелёный чай, 100 г',             8.50),
    ('Френч-пресс 600 мл',     'Стекло и нержавеющая сталь',              19.00),
    ('Кружка керамическая',    'Объём 350 мл, белая',                     6.20),
    ('Кофемолка ручная',       'Керамические жернова, регулировка помола', 34.00);

-- Заказ пользователя user@shop.test: 2 × кофе + 1 × френч-пресс
INSERT INTO orders (user_id, amount)
SELECT id, 0 FROM users WHERE email = 'user@shop.test';

INSERT INTO orders_description (order_id, item_id, quantity)
SELECT o.id, i.id, v.qty
FROM (SELECT MAX(id) AS id FROM orders) o
CROSS JOIN (VALUES ('Кофе Арабика 1 кг', 2), ('Френч-пресс 600 мл', 1)) AS v(name, qty)
JOIN items i ON i.name = v.name;

-- Сумма заказа = сумма (цена × количество) по позициям
UPDATE orders o
SET amount = s.total
FROM (
    SELECT od.order_id, SUM(i.price * od.quantity) AS total
    FROM orders_description od
    JOIN items i ON i.id = od.item_id
    GROUP BY od.order_id
) s
WHERE s.order_id = o.id;

COMMIT;
