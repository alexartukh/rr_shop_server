# Be sure to restart your server when you modify this file.

# CORS: разрешаем браузеру читать ответы API со страниц React-клиента,
# если клиент открыт с другого адреса (хост или порт), чем Rails.
# Read more: https://github.com/cyu/rack-cors

# Адреса клиента, которым можно обращаться к API.
# По умолчанию — dev-сервер Vite. Для продакшена задайте переменную окружения,
# например: CORS_ORIGINS="https://shop.example.com,https://www.shop.example.com"
cors_origins = ENV.fetch("CORS_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173")
                  .split(",")
                  .map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*cors_origins)

    resource "/api/*",
      headers: :any,
      # JWT-токен приходит в заголовке ответа Authorization.
      # Без expose браузер не даст JS прочитать этот заголовок.
      expose: ["Authorization"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
