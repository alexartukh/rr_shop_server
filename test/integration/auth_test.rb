require "test_helper"

# Регистрация, вход и выход (Devise + JWT)
class AuthTest < ActionDispatch::IntegrationTest
  test "registration returns a token and never grants admin role" do
    post "/api/v1/users",
         params: { user: { email: "new@example.com", password: PASSWORD,
                           first_name: "New", last_name: "User", role: "ADMIN" } },
         as: :json

    assert_response :created
    assert response.headers["Authorization"].present?
    assert_equal User::ROLE_USER, User.find_by(email: "new@example.com").role
  end

  test "sign in with a wrong password fails" do
    user = create_user(email: "user@example.com")

    post "/api/v1/users/sign_in", params: { user: { email: user.email, password: "wrong" } }, as: :json
    assert_response :unauthorized
  end

  test "token stops working after sign out" do
    headers = auth_headers(create_user(email: "user@example.com"))

    get "/api/v1/me", headers: headers, as: :json
    assert_response :success

    delete "/api/v1/users/sign_out", headers: headers, as: :json
    assert_response :no_content

    get "/api/v1/me", headers: headers, as: :json
    assert_response :unauthorized
  end
end
