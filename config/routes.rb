Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Регистрация, вход и выход (Devise + JWT):
  #   POST   /api/v1/users           → регистрация
  #   POST   /api/v1/users/sign_in   → вход
  #   DELETE /api/v1/users/sign_out  → выход
  # devise_for стоит вне namespace намеренно: внутри него Devise переименовал бы
  # помощники в current_api_v1_user / authenticate_api_v1_user!
  devise_for :users,
             path: "api/v1/users",
             controllers: {
               sessions: "api/v1/users/sessions",
               registrations: "api/v1/users/registrations"
             },
             defaults: { format: :json }

  namespace :api do
    namespace :v1 do
      resources :items, only: [:index, :show]

      # Всё ниже — только для вошедших (токен в заголовке Authorization)
      # GET /api/v1/me — мой профиль, PATCH/PUT /api/v1/me — изменить имя и фамилию
      resource :me, only: [:show, :update], controller: "me"
      post "placeorder", to: "orders#create"
      resources :orders, only: [:index, :show]   # мои заказы и один мой заказ

      # Админка — только для пользователей с ролью ADMIN
      namespace :admin do
        resources :items                                   # все 5 действий
        resources :users, only: [:index, :show, :update]
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
