module Api
  module V1
    class OrdersController < ApplicationController
      # POST /api/v1/placeorder
      #
      # Тело запроса (JSON):
      #   {
      #     "user_id": 2,
      #     "items": [ { "item_id": 1, "quantity": 2 }, { "item_id": 3, "quantity": 1 } ]
      #   }
      #
      # ВРЕМЕННО: user_id передаёт клиент. Когда появится авторизация,
      # пользователь будет определяться по токену, а не браться из запроса.
      def create
        user = User.find_by(id: params[:user_id])
        return render_error("User not found", :not_found) unless user

        quantities = parse_quantities(params[:items])
        return render_error("Items must be a non-empty list of { item_id, quantity > 0 }") unless quantities

        items = Item.where(id: quantities.keys).index_by(&:id)
        missing = quantities.keys - items.keys
        return render_error("Items not found: #{missing.join(', ')}") if missing.any?

        # Сумму считаем на сервере по ценам из базы, а не берём от клиента
        amount = quantities.sum { |item_id, qty| items[item_id].price * qty }

        # Заказ и все его позиции создаются вместе: либо всё, либо ничего
        order = Order.transaction do
          new_order = Order.create!(user: user, amount: amount)
          quantities.each do |item_id, qty|
            new_order.lines.create!(item: items[item_id], quantity: qty)
          end
          new_order
        end

        render json: order_json(order, items), status: :created
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

      def order_json(order, items)
        {
          id: order.id,
          user_id: order.user_id,
          amount: order.amount,
          created_at: order.created_at,
          items: order.lines.map do |line|
            item = items[line.item_id]
            { item_id: item.id, name: item.name, price: item.price, quantity: line.quantity }
          end
        }
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { error: message }, status: status
      end
    end
  end
end
