# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'
require 'ostruct'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d'
PASSWORD = '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'
SHOP_NAME = 'jmhsoft'

module ShopifySync
  class GetOrdersService
    def self.call
      service = new
      service.getorders
    end

    def getorders
      orders = ShopifyAPI::Order.find(:all)

      if orders.empty?
        OpenStruct.new('success?' => false, 'error_code' => 'Error code 404, there is no pending order.', 'data' => nil)
      else
        OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { orders: orders })
      end
    end

    private

    def initialize
      initiate_api
    end

    def initiate_api
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
