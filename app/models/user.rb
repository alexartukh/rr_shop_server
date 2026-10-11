class User < ApplicationRecord
  # Отзыв JWT-токенов через колонку jti: при выходе jti меняется,
  # и все выданные ранее токены пользователя перестают действовать.
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, # вход по email + паролю, bcrypt-хэш в encrypted_password
         :registerable,             # регистрация
         :validatable,              # проверка формата email, уникальности и длины пароля
         :jwt_authenticatable,      # вход по JWT-токену в заголовке Authorization
         jwt_revocation_strategy: self

  ROLE_ADMIN = "ADMIN".freeze
  ROLE_USER  = "USER".freeze
  ROLES = [ROLE_ADMIN, ROLE_USER].freeze

  has_many :orders

  # В базе это VARCHAR(100), поэтому и длину ограничиваем здесь —
  # чтобы вместо ошибки базы клиент получил понятное сообщение
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == ROLE_ADMIN
  end

  # Данные пользователя для ответов API.
  # Только явный список полей: encrypted_password и jti наружу не отдаём.
  def as_api_json
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      role: role
    }
  end
end
