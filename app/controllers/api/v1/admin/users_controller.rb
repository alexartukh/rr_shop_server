module Api
  module V1
    module Admin
      # Управление пользователями:
      #   GET    /api/v1/admin/users       — список
      #   GET    /api/v1/admin/users/:id   — один пользователь
      #   POST   /api/v1/admin/users       — создать
      #   PATCH  /api/v1/admin/users/:id   — изменить
      #   DELETE /api/v1/admin/users/:id   — удалить
      #
      # Тело для POST:
      #   { "user": { "email": "...", "password": "...", "first_name": "...", "last_name": "...", "role": "USER" } }
      # Тело для PATCH (любые из полей):
      #   { "user": { "first_name": "...", "last_name": "...", "email": "...", "role": "ADMIN" } }
      class UsersController < BaseController
        before_action :set_user, only: [:show, :update, :destroy]

        def index
          render json: User.order(:id).map { |user| admin_user_json(user) }
        end

        def show
          render json: admin_user_json(@user)
        end

        def create
          # Пароль хэширует Devise: присваиваем password, в базу ляжет encrypted_password.
          # Роль не прислали — останется USER (значение по умолчанию в базе).
          user = User.new(create_params)

          if user.save
            render json: admin_user_json(user), status: :created
          else
            render_errors(user)
          end
        end

        def update
          attrs = update_params
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

        def destroy
          if @user == current_user
            return render json: { errors: ["You cannot delete yourself"] }, status: :unprocessable_content
          end

          @user.destroy!
          head :no_content
        rescue ActiveRecord::InvalidForeignKey
          # В базе: orders.user_id ... ON DELETE RESTRICT — история заказов не теряется
          render json: { error: "User has orders and cannot be deleted" }, status: :conflict
        end

        private

        def set_user
          @user = User.find_by(id: params[:id])
          render json: { error: "User not found" }, status: :not_found unless @user
        end

        # При создании пароль обязателен (проверяет Devise: минимум 6 символов)
        def create_params
          params.fetch(:user, {}).permit(:email, :password, :first_name, :last_name, :role)
        end

        # При редактировании пароль не меняется
        def update_params
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
