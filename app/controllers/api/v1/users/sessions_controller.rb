module Api
  module V1
    module Users
      # POST   /api/v1/users/sign_in   — вход, токен приходит в заголовке Authorization
      # DELETE /api/v1/users/sign_out  — выход, токен отзывается
      class SessionsController < Devise::SessionsController
        include RackSessionsFix

        private

        # Успешный вход: отдаём данные пользователя.
        # Сам токен devise-jwt добавит в заголовок ответа автоматически.
        def respond_with(resource, _opts = {})
          render json: { user: resource.as_api_json }, status: :ok
        end

        # Devise проверяет «а вы вообще вошли?» по сессии, которой у нас нет.
        # Проверяем по токену: нет действующего токена — 401.
        def verify_signed_out_user
          return if warden.authenticate(scope: resource_name)

          respond_to_on_destroy(non_navigational_status: :unauthorized)
        end

        # Ответ на выход. Devise строит его через respond_to (выбор между HTML-редиректом
        # и пустым ответом), а в API-контроллерах Rails метода respond_to нет — был NoMethodError.
        # Нам редирект не нужен: просто пустой ответ (204 после выхода, 401 — если не были вошедшим).
        def respond_to_on_destroy(non_navigational_status: :no_content)
          head non_navigational_status
        end
      end
    end
  end
end
