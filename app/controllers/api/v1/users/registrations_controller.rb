module Api
  module V1
    module Users
      # POST /api/v1/users — регистрация, токен приходит в заголовке Authorization
      class RegistrationsController < Devise::RegistrationsController
        include RackSessionsFix

        before_action :configure_sign_up_params, only: :create

        private

        # По умолчанию Devise принимает только email, password, password_confirmation.
        # Разрешаем имя и фамилию. role НЕ разрешаем: роль всегда USER по умолчанию.
        def configure_sign_up_params
          devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
        end

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: { user: resource.as_api_json }, status: :created
          else
            render json: { errors: resource.errors.full_messages }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
