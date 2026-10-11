# В режиме API (config.api_only = true) в Rails нет сессий, а Devise при входе,
# регистрации и выходе всё равно обращается к request.env["rack.session"].
# Подкладываем пустую «фальшивую» сессию: Devise доволен, а реально ничего
# не хранится — состояние входа живёт только в JWT-токене.
module RackSessionsFix
  extend ActiveSupport::Concern

  class FakeRackSession < Hash
    def enabled?
      false
    end

    def destroy; end
  end

  included do
    before_action :set_fake_rack_session
  end

  private

  def set_fake_rack_session
    request.env["rack.session"] ||= FakeRackSession.new
  end
end
