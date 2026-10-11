module Api
  module V1
    module Admin
      # Управление товарами:
      #   GET    /api/v1/admin/items       — список
      #   GET    /api/v1/admin/items/:id   — один товар
      #   POST   /api/v1/admin/items       — создать
      #   PATCH  /api/v1/admin/items/:id   — изменить
      #   DELETE /api/v1/admin/items/:id   — удалить
      # Тело для POST/PATCH: { "item": { "name": "...", "description": "...", "price": 9.90 } }
      class ItemsController < BaseController
        before_action :set_item, only: [ :show, :update, :destroy ]

        def index
          render json: Item.order(:id)
        end

        def show
          render json: @item
        end

        def create
          item = Item.new(item_params)

          if item.save
            render json: item, status: :created
          else
            render_errors(item)
          end
        end

        def update
          attrs = item_params
          if attrs.empty?
            return render json: { errors: [ "Nothing to update: send name, description and/or price" ] },
                          status: :unprocessable_content
          end

          if @item.update(attrs)
            render json: @item
          else
            render_errors(@item)
          end
        end

        def destroy
          @item.destroy!
          head :no_content
        rescue ActiveRecord::InvalidForeignKey
          # В базе: orders_description.item_id ... ON DELETE RESTRICT
          render json: { error: "Item is used in orders and cannot be deleted" }, status: :conflict
        end

        private

        # @item — переменная экземпляра: она видна во всех методах контроллера,
        # поэтому set_item находит товар один раз для show/update/destroy
        def set_item
          @item = Item.find_by(id: params[:id])
          render json: { error: "Item not found" }, status: :not_found unless @item
        end

        def item_params
          params.fetch(:item, {}).permit(:name, :description, :price)
        end
      end
    end
  end
end
