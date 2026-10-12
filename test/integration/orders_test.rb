require "test_helper"

# Оформление и просмотр заказов
class OrdersTest < ActionDispatch::IntegrationTest
  setup do
    @user   = create_user(email: "buyer@example.com")
    @coffee = Item.create!(name: "Coffee", price: 10.50)
    @mug    = Item.create!(name: "Mug", price: 4.00)
  end

  test "guest cannot see orders" do
    get "/api/v1/orders", as: :json
    assert_response :unauthorized
  end

  test "placeorder computes amount from database prices" do
    # amount от клиента должен игнорироваться, повторы товара — складываться
    post "/api/v1/placeorder",
         params: { amount: 1, items: [ { item_id: @coffee.id, quantity: 1 },
                                       { item_id: @mug.id, quantity: 3 },
                                       { item_id: @coffee.id, quantity: 1 } ] },
         headers: auth_headers(@user), as: :json

    assert_response :created
    assert_equal BigDecimal("33.00"), BigDecimal(json["amount"]) # 2 × 10.50 + 3 × 4.00
    assert_equal 2, json["items"].size

    order = @user.orders.last
    assert_equal BigDecimal("33.00"), order.amount
    assert_equal 2, order.lines.find_by(item: @coffee).quantity
  end

  test "placeorder rejects invalid items and creates nothing" do
    headers = auth_headers(@user)

    [ [], [ { item_id: @coffee.id, quantity: 0 } ], [ { item_id: 999_999, quantity: 1 } ] ].each do |items|
      post "/api/v1/placeorder", params: { items: items }, headers: headers, as: :json
      assert_response :unprocessable_content
    end

    assert_equal 0, Order.count
  end

  test "user cannot see someone else's order" do
    other = create_user(email: "other@example.com")
    order = Order.create!(user: other, amount: 10.50)
    order.lines.create!(item: @coffee, quantity: 1)

    get "/api/v1/orders/#{order.id}", headers: auth_headers(@user), as: :json
    assert_response :not_found
  end
end
