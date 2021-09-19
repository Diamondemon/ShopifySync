# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'

module ShopifySync
  # Service to retrieve all pending orders
  class GetOrdersService
    attr_accessor :shopify_orders, :shopify_login_info, :shopify_params

    def self.call(params = {})
      new(params).call
    end

    def call
      pull_orders_from_shopify
    rescue ActiveResource::ClientError => e
      error_details = handle_error(e)
      OpenStruct.new('success?' => false, 'error_code' => error_details[:code],
                     'error_message' => error_details[:message], 'data' => { error: e })
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { orders: shopify_orders })
    end

    private

    def initialize(params)
      @shopify_login_info = params[:login_info]
      @shopify_params = params[:params]
      initiate_shopify_api
    end

    def initiate_shopify_api
      ConnectionService.call(shopify_login_info)
    end

    def pull_orders_from_shopify
      @shopify_orders = ShopifyAPI::Order.find(:all, params: shopify_params)
      raise(ActiveResource::ResourceNotFound, '') if shopify_orders.empty?
    end

    def handle_error(err)
      if err.instance_of?(ActiveResource::ResourceNotFound)
        { code: '404', message: 'Error code 404 Not Found; wrong shop name or no pending order with params.' }
      elsif err.instance_of?(ActiveResource::BadRequest)
        { code: '400', message: 'Error code 400 Bad request, an order id was expected.' }
      elsif err.instance_of?(ActiveResource::UnauthorizedAccess)
        { code: '401', message: 'Error code 401, Invalid password' }
      elsif err.instance_of?(ActiveResource::ForbiddenAccess)
        { code: '403', message: 'Error code 403, Invalid API Key' }
      else
        { code: '4XX', message: 'Unhandled error 4XX' }
      end
    end
  end
end
