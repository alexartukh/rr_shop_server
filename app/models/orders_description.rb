class OrdersDescription < ApplicationRecord
  # По соглашению Rails искал бы таблицу "orders_descriptions" (с «s»),
  # поэтому имя таблицы указываем явно.
  self.table_name = "orders_description"

  belongs_to :order
  belongs_to :item

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
