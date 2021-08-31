# frozen_string_literal: true

require 'awesome_print'
require 'shopify_api'
require 'ostruct'

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
      initiate_api(params)
      getorder(params)
      fill_fulfillment(params)
    end

    def getorder(params)
      @order = GetOrderService.call(params)
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

    def initiate_api(login_info)
      shop_url = "https://#{login_info[:api_key]}:#{login_info[:password]}@#{login_info[:shop_name]}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
