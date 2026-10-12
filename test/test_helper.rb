ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Общие помощники для тестов API (тесты запросов лежат в test/integration/)
class ActionDispatch::IntegrationTest
  PASSWORD = "secret123".freeze

  def create_user(email:, role: User::ROLE_USER)
    User.create!(email: email, password: PASSWORD, first_name: "Test", last_name: "User", role: role)
  end

  # Входим через настоящий эндпоинт и берём JWT из заголовка ответа —
  # так тест проверяет и сам вход
  def auth_headers(user)
    post "/api/v1/users/sign_in", params: { user: { email: user.email, password: PASSWORD } }, as: :json
    assert_response :success
    token = response.headers["Authorization"]
    assert token.present?, "sign_in must return a token in the Authorization header"
    { "Authorization" => token }
  end

  def json
    response.parsed_body
  end
end
