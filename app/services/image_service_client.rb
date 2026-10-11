require "net/http"
require "json"

# Клиент стороннего сервиса картинок (GIF MAKER).
#
#   POST {url}/login  { "login": "...", "password": "..." }  →  { "token": "..." }
#   GET  {url}/g?token=...&t=...&template=...                →  картинка
#
# Токен получаем лениво — при первом запросе картинки — и держим в памяти процесса.
# Если сервис ответил 401/403 (токен истёк), логинимся заново и повторяем запрос один раз.
class ImageServiceClient
  class Error < StandardError; end

  Image = Struct.new(:body, :content_type, keyword_init: true)

  NETWORK_ERRORS = [
    SocketError, SystemCallError, IOError, Timeout::Error,
    Net::OpenTimeout, Net::ReadTimeout, Net::HTTPBadResponse, OpenSSL::SSL::SSLError
  ].freeze

  DEFAULT_LOCK = Mutex.new

  # Один общий клиент на весь процесс Rails — чтобы токен переиспользовался между запросами
  def self.default
    DEFAULT_LOCK.synchronize do
      @default ||= begin
        cfg = Rails.application.config.x.image_service
        new(url: cfg.url, login: cfg.login, password: cfg.password)
      end
    end
  end

  def initialize(url:, login:, password:, open_timeout: 5, read_timeout: 20)
    @base_uri = URI(url.to_s.chomp("/"))
    @login = login.to_s
    @password = password.to_s
    @open_timeout = open_timeout
    @read_timeout = read_timeout
    @token = nil
    @lock = Mutex.new # Puma обслуживает запросы в нескольких потоках
  end

  def fetch_image(text:, template:)
    token = current_token
    response = request_image(text, template, token)

    if auth_failed?(response)
      token = refresh_token!(token)
      response = request_image(text, template, token)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Image service responded with HTTP #{response.code}"
    end

    content_type = response["Content-Type"].to_s
    if content_type.include?("json")
      raise Error, "Image service returned an error: #{response.body.to_s[0, 200]}"
    end

    Image.new(body: response.body, content_type: content_type.empty? ? "image/gif" : content_type)
  end

  private

  def current_token
    @lock.synchronize { @token ||= login! }
  end

  # Логинимся заново, только если токен не обновил уже другой поток
  def refresh_token!(stale_token)
    @lock.synchronize do
      @token = nil if @token == stale_token
      @token ||= login!
    end
  end

  def login!
    uri = endpoint("/login")
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = { login: @login, password: @password }.to_json
    response = perform(uri, request)

    body = response.body.to_s
    data = begin
      JSON.parse(body)
    rescue JSON::ParserError
      raise Error, "Login failed: HTTP #{response.code}, response is not JSON: #{body[0, 300]}"
    end

    # Успех = в ответе есть непустой token. Поле error не проверяем отдельно:
    # в Ruby 0 и "" — это «истина» (в отличие от JavaScript), и {"error": 0, "token": "..."}
    # ошибочно считался бы неудачей.
    token = data["token"] if data.is_a?(Hash)
    if response.is_a?(Net::HTTPSuccess) && token.is_a?(String) && !token.empty?
      return token
    end

    message = data["message"] if data.is_a?(Hash)
    raise Error, "Login failed: HTTP #{response.code}, #{message || 'no token in response'}: #{body[0, 300]}"
  end

  def request_image(text, template, token)
    uri = endpoint("/g")
    # encode_uri_component кодирует пробел как %20 (а не "+")
    uri.query = {
      token: token, t: text, template: template
    }.map { |key, value| "#{key}=#{URI.encode_uri_component(value.to_s)}" }.join("&")

    perform(uri, Net::HTTP::Get.new(uri))
  end

  def auth_failed?(response)
    %w[401 403].include?(response.code)
  end

  def endpoint(path)
    URI("#{@base_uri}#{path}")
  end

  def perform(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = @open_timeout
    http.read_timeout = @read_timeout
    http.request(request)
  rescue *NETWORK_ERRORS => e
    raise Error, "Image service is unreachable: #{e.class}: #{e.message}"
  end
end
