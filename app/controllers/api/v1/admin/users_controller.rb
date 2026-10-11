module Api
  module V1
    module Admin
      # Управление пользователями:
      #   GET   /api/v1/admin/users       — список
      #   GET   /api/v1/admin/users/:id   — один пользователь
      #   PATCH /api/v1/admin/users/:id   — изменить
      # Тело для PATCH: { "user": { "first_name": "...", "last_name": "...", "email": "...", "role": "ADMIN" } }
      # Пароль здесь не меняется.
      class UsersController < BaseController
        before_action :set_user, only: [:show, :update]

        def index
          render json: User.order(:id).map { |user| admin_user_json(user) }
        end

        def show
          render json: admin_user_json(@user)
        end

        def update
          attrs = user_params
          if attrs.empty?
            return render json: { errors: ["Nothing to update: send first_name, last_name, email and/or role"] },
                          status: :unprocessable_content
          end

          # Защита от случайной потери доступа: админ не может снять роль ADMIN сам с себя
          if @user == current_user && attrs.key?(:role) && attrs[:role] != User::ROLE_ADMIN
            return render json: { errors: ["You cannot remove your own admin role"] },
                          status: :unprocessable_content
          end

          if @user.update(attrs)
            render json: admin_user_json(@user)
          else
            render_errors(@user)
          end
        end

        private

        def set_user
          @user = User.find_by(id: params[:id])
          render json: { error: "User not found" }, status: :not_found unless @user
        end

        def user_params
          params.fetch(:user, {}).permit(:first_name, :last_name, :email, :role)
        end

        # Админу дополнительно показываем даты и число заказов
        def admin_user_json(user)
          user.as_api_json.merge(
            orders_count: user.orders.count,
            created_at: user.created_at,
            updated_at: user.updated_at
          )
        end
      end
    end
  end
end
