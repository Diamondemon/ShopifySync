# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'

module ShopifySync
  # Service to retrieve the specified order
  class GetOrderService
    attr_accessor :shopify_order, :shopify_login_info, :shopify_order_id

    def self.call(params = {})
      new(params).call
    end

    def call
      pull_order_from_shopify
    rescue ActiveResource::ClientError => e
      error_details = handle_error(e)
      OpenStruct.new('success?' => false, 'error_code' => error_details[:code],
                     'error_message' => error_details[:message], 'data' => { error: e })
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { order: shopify_order })
    end

    private

    def initialize(params)
      @shopify_login_info = params[:login_info]
      @shopify_order_id = params[:order_id] || :last
      initiate_shopify_api
    end

    def initiate_shopify_api
      ConnectionService.call(shopify_login_info)
    end

    def pull_order_from_shopify
      @shopify_order = ShopifyAPI::Order.find(shopify_order_id)
    end

    def handle_error(err)
      if err.instance_of?(ActiveResource::ResourceNotFound)
        { code: '404', message: 'Error code 404 Not Found; check the id of the order or the name of the shop.' }
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
