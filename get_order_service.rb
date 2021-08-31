# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'
require 'ostruct'

module ShopifySync
  class GetOrderService
    def self.call(params = {})
      params[:order_id] = :last unless params.has_key?(:order_id)
      service = new(params)
      service.getorder(params[:order_id])
    end

    def getorder(id)
      order = ShopifyAPI::Order.find(id)
    rescue ActiveResource::ResourceNotFound
      OpenStruct.new('success?' => false, 'error_code' => 'Error code 404, Not Found; check the id of the order.',
                     'data' => nil)
    rescue ActiveResource::BadRequest
      OpenStruct.new('success?' => false, 'error_code' => 'Error code 400, Bad request, an order id was expected.',
                     'data' => nil)
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { order: order })
    end

    private

    def initialize(login_info)
      initiate_api(login_info)
    end

    def initiate_api(login_info)
      shop_url = "https://#{login_info[:api_key]}:#{login_info[:password]}@#{login_info[:shop_name]}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
