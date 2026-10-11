module Api
  module V1
    class ItemsController < ApplicationController
      
      # GET /api/v1/items
      def index
        items = Item.all
        render json: items
      end

      # GET /api/v1/items/:id
      def show
        item = Item.find_by(id: params[:id])

        if item
          render json: item
        else
          render json: { error: "Item not found" }, status: :not_found
        end
      end

    end # ItemsController
  end # module V1
end # module Api
