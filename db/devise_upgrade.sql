-- =====================================================================
--  Одноразовое обновление УЖЕ СОЗДАННОЙ базы под Devise + devise-jwt,
--  без потери данных (пользователи и заказы сохраняются).
--  Запуск:  psql -d shop_api_development -v ON_ERROR_STOP=1 -f db/devise_upgrade.sql
--  Для новой базы не нужен: db/init.sql уже содержит эти изменения.
-- =====================================================================

BEGIN;

-- Devise хранит bcrypt-хэш в колонке encrypted_password.
-- Формат хэша тот же, поэтому старые пароли продолжат работать.
ALTER TABLE users RENAME COLUMN password_digest TO encrypted_password;
ALTER TABLE users ALTER COLUMN encrypted_password SET DEFAULT '';

-- jti для отзыва JWT-токенов; существующие строки получат уникальные значения
ALTER TABLE users ADD COLUMN jti VARCHAR(255) NOT NULL DEFAULT gen_random_uuid()::text;
CREATE UNIQUE INDEX index_users_on_jti ON users (jti);

COMMIT;
