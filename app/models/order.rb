class Order < ApplicationRecord
  belongs_to :user

  # Позиции заказа (таблица orders_description).
  # dependent: :destroy — при удалении заказа удаляются и его позиции.
  has_many :lines, class_name: "OrdersDescription", dependent: :destroy
end
