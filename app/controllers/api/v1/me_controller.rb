module Api
  module V1
    # Профиль текущего пользователя (определяется по JWT-токену).
    class MeController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/me — кто я. Нужен клиенту при старте:
      # если токен из localStorage ещё действует — пользователь считается вошедшим.
      def show
        render json: current_user.as_api_json
      end

      # PATCH /api/v1/me — изменить своё имя и фамилию.
      # Тело: { "user": { "first_name": "Анна", "last_name": "Смирнова" } }
      # Можно прислать только одно из полей. Email, роль и пароль здесь не меняются.
      def update
        attrs = profile_params
        if attrs.empty?
          return render json: { errors: [ "Nothing to update: send first_name and/or last_name" ] },
                        status: :unprocessable_content
        end

        if current_user.update(attrs)
          render json: current_user.as_api_json
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      # Strong parameters: из всего, что прислал клиент, берём только эти два поля.
      # Всё остальное (role, email, id...) молча отбрасывается.
      def profile_params
        params.fetch(:user, {}).permit(:first_name, :last_name)
      end
    end
  end
end
