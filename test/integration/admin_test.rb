require "test_helper"

# Доступ к админскому API
class AdminTest < ActionDispatch::IntegrationTest
  test "regular user gets 403 on admin endpoints" do
    headers = auth_headers(create_user(email: "user@example.com"))

    get "/api/v1/admin/users", headers: headers, as: :json
    assert_response :forbidden

    post "/api/v1/admin/items", params: { item: { name: "Hack", price: 1 } }, headers: headers, as: :json
    assert_response :forbidden
    assert_equal 0, Item.count
  end

  test "admin can create an item" do
    headers = auth_headers(create_user(email: "admin@example.com", role: User::ROLE_ADMIN))

    post "/api/v1/admin/items", params: { item: { name: "Teapot", price: 15 } }, headers: headers, as: :json
    assert_response :created
    assert_equal "Teapot", Item.last.name
  end
end
