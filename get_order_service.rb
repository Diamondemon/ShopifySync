# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d'
PASSWORD = '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'
SHOP_NAME = 'jmhsoft'

module ShopifySync
  class GetOrderService
    def self.call
      new
    end

    private

    def initialize
      initiate_api
      getall
      print_all
    end

    def initiate_api
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end

    def getall
      @shop = ShopifyAPI::Shop.current

      @products = ShopifyAPI::Product.find(:all, params: { limit: 50 })
    end

    def print_all
      ap @products
      ap @shop
    end
  end
end

ShopifySync::GetOrderService.call
