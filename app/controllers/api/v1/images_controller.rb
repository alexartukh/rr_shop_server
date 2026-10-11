module Api
  module V1
    # GET /api/v1/image?t=Raspberry%20Pi%20Camera%20Module%203&template=100
    #
    # Посредник к стороннему сервису картинок: принимает t и template,
    # добавляет токен сервиса и возвращает картинку как есть.
    # Открыт всем — картинки подключаются в <img src="...">, а тег <img>
    # не умеет отправлять заголовок Authorization.
    class ImagesController < ApplicationController
      MAX_TEXT_LENGTH = 200

      def show
        text = params[:t].to_s.strip
        template = Integer(params[:template].to_s, 10, exception: false)

        if text.empty? || text.length > MAX_TEXT_LENGTH
          return render json: { error: "Parameter t is required (1..#{MAX_TEXT_LENGTH} characters)" },
                        status: :bad_request
        end
        unless template
          return render json: { error: "Parameter template must be an integer" }, status: :bad_request
        end

        image = ImageServiceClient.default.fetch_image(text: text, template: template)

        # Одинаковые t + template дают одинаковую картинку — пусть браузер кэширует сутки
        expires_in 1.day, public: true
        send_data image.body, type: image.content_type, disposition: "inline"
      rescue ImageServiceClient::Error => e
        Rails.logger.warn("[ImageService] #{e.message}")
        render json: { error: "Image service unavailable" }, status: :bad_gateway
      end
    end
  end
end
