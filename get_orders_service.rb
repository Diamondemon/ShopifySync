# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'
require 'ostruct'

module ShopifySync
  class GetOrdersService
    def self.call(params = {})
      service = new(params)
      service.getorders(params[:params])
    end

    def getorders(params)
      orders = ShopifyAPI::Order.find(:all, params: params)

      if orders.empty?
        OpenStruct.new('success?' => false,
                       'error_code' => 'Error code 404, there is no pending order with the specified requirements.',
                       'data' => nil)
      else
        OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { orders: orders })
      end
    end

    private

    def initialize(params)
      initiate_api(params[:login_info])
    end

    def initiate_api(login_info)
      shop_url = "https://#{login_info[:api_key]}:#{login_info[:password]}@#{login_info[:shop_name]}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
