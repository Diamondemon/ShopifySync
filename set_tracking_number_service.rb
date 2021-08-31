# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'
require 'ostruct'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d'
PASSWORD = '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'
SHOP_NAME = 'jmhsoft'

module ShopifySync
  class SetTrackingNumberService
    attr_accessor :order, :fulfillment

    def self.call(params)
      service = new(params)
      service.fulfillment
    end

    private

    def initialize(params)
      @tracking_number = params[:tracking_number]
      initiate_api
      getorder(params[:order_id])
      fill_fulfillment(params)
    end

    def getorder(order_id)
      @order = GetOrderService.call(order_id)
      raise @order unless order.success?
    end

    def fill_fulfillment(tracking_info)
      @fulfillment = ShopifyAPI::Fulfillment.new
      @fulfillment.attributes.merge!({ tracking_number: tracking_info[:tracking_number],
                                       tracking_url: tracking_info[:tracking_url],
                                       tracking_company: tracking_info[:tracking_company] })
      line_items = []
      @order.data[:order].line_items.each { |item| line_items.append({ id: item.id })}
      @fulfillment.attributes[:line_items] = line_items
    end

    def initiate_api
      shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
