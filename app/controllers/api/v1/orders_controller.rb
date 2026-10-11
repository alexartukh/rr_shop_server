module Api
  module V1
    class OrdersController < ApplicationController
      # Все действия — только для вошедших. Пользователь определяется по
      # JWT-токену из заголовка Authorization (current_user). Без токена — 401.
      before_action :authenticate_user!

      # GET /api/v1/orders
      # Список заказов текущего пользователя, новые сверху.
      def index
        orders = current_user.orders.includes(:lines).order(created_at: :desc)

        render json: orders.map { |order| order_summary_json(order) }
      end

      # GET /api/v1/orders/:id
      # Один заказ с позициями. Ищем только среди заказов текущего пользователя,
      # поэтому чужой заказ по его id не получить.
      def show
        order = current_user.orders.includes(lines: :item).find_by(id: params[:id])
        return render_error("Order not found", :not_found) unless order

        render json: order_json(order)
      end

      # POST /api/v1/placeorder
      #
      # Тело запроса (JSON):
      #   {
      #     "items": [ { "item_id": 1, "quantity": 2 }, { "item_id": 3, "quantity": 1 } ]
      #   }
      # Заказ оформляется на текущего пользователя (из токена).
      def create
        quantities = parse_quantities(params[:items])
        return render_error("Items must be a non-empty list of { item_id, quantity > 0 }") unless quantities

        items = Item.where(id: quantities.keys).index_by(&:id)
        missing = quantities.keys - items.keys
        return render_error("Items not found: #{missing.join(', ')}") if missing.any?

        # Сумму считаем на сервере по ценам из базы, а не берём от клиента
        amount = quantities.sum { |item_id, qty| items[item_id].price * qty }

        # Заказ и все его позиции создаются вместе: либо всё, либо ничего
        order = Order.transaction do
          new_order = Order.create!(user: current_user, amount: amount)
          quantities.each do |item_id, qty|
            new_order.lines.create!(item: items[item_id], quantity: qty)
          end
          new_order
        end

        render json: order_json(order), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      end

      private

      # [{ "item_id" => "1", "quantity" => "2" }, ...]  →  { 1 => 2, ... }
      # Повторяющиеся товары складываются. При любой ошибке возвращает nil.
      def parse_quantities(raw_items)
        return nil unless raw_items.is_a?(Array) && raw_items.any?

        raw_items.each_with_object(Hash.new(0)) do |entry, result|
          return nil unless entry.respond_to?(:key?)

          # .to_s и основание 10 — чтобы "2.5" или "0x1A" отклонялись, а не превращались в число
          item_id = Integer(entry[:item_id].to_s, 10, exception: false)
          qty     = Integer(entry[:quantity].to_s, 10, exception: false)
          return nil if item_id.nil? || qty.nil? || qty <= 0

          result[item_id] += qty
        end
      end

      # Краткие данные заказа — для списка
      def order_summary_json(order)
        {
          id: order.id,
          amount: order.amount,
          created_at: order.created_at,
          items_count: order.lines.map(&:quantity).sum
        }
      end

      # Полные данные заказа — с позициями
      def order_json(order)
        {
          id: order.id,
          user_id: order.user_id,
          amount: order.amount,
          created_at: order.created_at,
          items: order.lines.map do |line|
            {
              item_id: line.item_id,
              name: line.item.name,
              price: line.item.price,
              quantity: line.quantity
            }
          end
        }
      end

      def render_error(message, status = :unprocessable_content)
        render json: { error: message }, status: status
      end
    end # OrdersController
  end # module V1
end # module Api
