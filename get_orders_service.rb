# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'
require './exceptions'

module ShopifySync
  # Service to retrieve all pending orders
  class GetOrdersService
    attr_accessor :feedback

    def self.call(params = {})
      service = new(params)
      service.feedback
    end

    private

    def initialize(params)
      ConnectionService.call(params[:login_info])
    rescue ActiveResource::UnauthorizedAccess => e
      @feedback = OpenStruct.new('success?' => false, 'error_code' => 'Error code 401, Invalid credentials',
                                 'data' => { error: e })
    else
      getorders(params[:params])
    end

    def getorders(params)
      orders = ShopifyAPI::Order.find(:all, params: params)
    rescue ActiveResource::ClientError => e
      error_code = handle_error(e)
      @feedback = OpenStruct.new('success?' => false, 'error_code' => error_code,
                                 'data' => { error: e })
    else
      verify_orders(orders)
    end

    def verify_orders(orders)
      if orders.empty?
        error_code = 'Error code 404, there is no pending order with the specified requirements.'
        @feedback = OpenStruct.new('success?' => false,
                                   'error_code' => error_code,
                                   'data' => nil)
      else
        @feedback = OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { orders: orders })
      end
    end

    def handle_error(err)
      if err.instance_of?(ActiveResource::ResourceNotFound)
        'Error code 404 Not Found; check the id of the order.'
      elsif err.instance_of?(ActiveResource::BadRequest)
        'Error code 400 Bad request, an order id was expected.'
      elsif err.instance_of?(ActiveResource::UnauthorizedAccess)
        'Error code 401, Invalid credentials'
      elsif err.instance_of?(ActiveResource::ForbiddenAccess)
        'Error code 403, Invalid API Key'
      else
        'Unhandled error'
      end
    end
  end
end
