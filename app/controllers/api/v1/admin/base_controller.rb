module Api
  module V1
    module Admin
      # Общий родитель всех админских контроллеров.
      # Сначала проверяем, что пользователь вошёл (401), затем — что он админ (403).
      class BaseController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!

        private

        def require_admin!
          return if current_user.admin?

          render json: { error: "Admin access required" }, status: :forbidden
        end

        def render_errors(record)
          render json: { errors: record.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end
end
