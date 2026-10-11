# Shop API (Ruby on Rails)

Серверная часть тестового интернет-магазина: JSON API на Rails 8 (режим `--api`),
PostgreSQL, аутентификация Devise + JWT. Клиент на React — отдельный репозиторий `shop-client`.

## Демо

- Магазин: `https://<shop-client>.onrender.com`
- API: `https://<shop-api>.onrender.com/api/v1/items`

> Бесплатный сервер засыпает после 15 минут без запросов.
> **Первая загрузка может занять до минуты** — потом всё работает быстро.

Тестовые пользователи (пароль у всех `123`):

| Email | Роль |
|---|---|
| `alex@example.com` | ADMIN |
| `test@example.com` | USER |
| `denis@example.com` | USER |

## Стек

- Ruby 3.3, Rails 8.1 (API-only)
- PostgreSQL (локально; в демо — Neon)
- Devise + devise-jwt — регистрация, вход, JWT-токен в заголовке `Authorization`
- rack-cors — доступ к API с адреса клиента

## Эндпоинты

Все адреса начинаются с `/api/v1`. Токен передаётся в заголовке `Authorization: Bearer <token>`;
его возвращают регистрация и вход в заголовке ответа `Authorization`.

| Метод | Адрес | Доступ | Что делает |
|---|---|---|---|
| GET | `/items` | все | список товаров |
| GET | `/items/:id` | все | один товар |
| GET | `/image?t=<текст>&template=<число>` | все | картинка от стороннего сервиса (Rails — посредник) |
| POST | `/users` | все | регистрация `{ "user": { email, password, first_name, last_name } }` |
| POST | `/users/sign_in` | все | вход `{ "user": { email, password } }` |
| DELETE | `/users/sign_out` | вошедшие | выход (токен отзывается) |
| GET / PATCH | `/me` | вошедшие | мой профиль / изменить имя и фамилию |
| POST | `/placeorder` | вошедшие | оформить заказ `{ "items": [ { item_id, quantity } ] }` |
| GET | `/orders`, `/orders/:id` | вошедшие | мои заказы / один заказ |
| GET, POST, PATCH, DELETE | `/admin/items[/:id]` | ADMIN | управление товарами |
| GET, POST, PATCH, DELETE | `/admin/users[/:id]` | ADMIN | управление пользователями |

Сумма заказа считается на сервере по ценам из базы. Роль при регистрации всегда `USER`.

## Запуск локально

Требуется Ruby 3.3 и PostgreSQL.

```bash
bundle install
bin/rails db:create
psql -d shop_api_development -v ON_ERROR_STOP=1 -f db/init.sql   # схема + тестовые данные
bin/rails server -b 0.0.0.0
```

Схема базы описана в `db/init.sql` (скрипт можно запускать повторно — он пересоздаёт таблицы).

## Переменные окружения

| Переменная | Где нужна | Описание |
|---|---|---|
| `DATABASE_URL` | production | строка подключения к PostgreSQL |
| `RAILS_MASTER_KEY` | production | содержимое `config/master.key` (в git не хранится) |
| `DEVISE_JWT_SECRET_KEY` | production | ключ подписи JWT (`bin/rails secret`) |
| `CORS_ORIGINS` | везде | адреса клиента через запятую; по умолчанию `http://localhost:5173` |
| `IMAGE_SERVICE_URL` | по желанию | адрес сервиса картинок; в production без него картинки отключены |
| `IMAGE_SERVICE_LOGIN`, `IMAGE_SERVICE_PASSWORD` | по желанию | учётные данные сервиса картинок |

Настройки сервиса картинок: `config/image_service.yml`.

## Размещение (Render + Neon)

1. **База — Neon.** Создать проект, выполнить `db/init.sql` на его базе.
2. **Render → New → Web Service**, этот репозиторий, тариф Free, регион как у базы:
   - Runtime: **Ruby**
   - Build Command: `bundle install`
   - Start Command: `bundle exec puma -C config/puma.rb`
   - Environment: `RAILS_ENV=production`, `DATABASE_URL` (строка Neon *без пула*, `DATABASE_URL_UNPOOLED`),
     `RAILS_MASTER_KEY`, `DEVISE_JWT_SECRET_KEY`, `CORS_ORIGINS` = адрес клиента на Render.
3. Проверка: `https://<shop-api>.onrender.com/api/v1/items`.

В production кэш, фоновые задачи и WebSocket работают в памяти процесса
(`config/environments/production.rb`, `config/cable.yml`), поэтому нужна одна база.
