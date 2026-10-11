class Item < ApplicationRecord
  # Проверки дублируют ограничения базы (NOT NULL, VARCHAR(255), CHECK price >= 0),
  # но дают понятные сообщения об ошибках вместо ошибки PostgreSQL
  validates :name, presence: true, length: { maximum: 255 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
