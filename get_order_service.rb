# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'
require './exceptions'

module ShopifySync
  class GetOrderService
    attr_accessor :feedback

    def self.call(params = {})
      params[:order_id] = :last unless params.key?(:order_id)
      service = new(params)
      service.feedback
    end

    private

    def initialize(params)
      ConnectionService.call(params[:login_info])
      getorder(params[:order_id])
    end

    def getorder(id)
      order = ShopifyAPI::Order.find(id)
    rescue ActiveResource::ClientError => e
      error_code = handle_error(e)
      @feedback = OpenStruct.new('success?' => false, 'error_code' => error_code,
                                 'data' => { error: e })
    else
      @feedback = OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { order: order })
    end

    def handle_error(err)
      if err.instance_of?(ActiveResource::ResourceNotFound)
        'Error code 404 Not Found; check the id of the order or the name of the shop.'
      elsif err.instance_of?(ActiveResource::BadRequest)
        'Error code 400 Bad request, an order id was expected.'
      elsif err.instance_of?(ActiveResource::UnauthorizedAccess)
        'Error code 401, Invalid password'
      elsif err.instance_of?(ActiveResource::ForbiddenAccess)
        'Error code 403, Invalid API Key'
      else
        'Unhandled error'
      end
    end
  end
end
