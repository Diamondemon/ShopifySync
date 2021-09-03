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
      initiate_api(params[:login_info])
      getorder(params)
      fill_fulfillment(params[:tracking_info])
      save_fulfillment
    end

    def getorder(params)
      @order = GetOrderService.call({ login_info: params[:login_info], order_id: params[:order_id] })
      @order_items = @order.data[:order].line_items
      @line_items = []
      @order_items.each do |item|
        @line_items.append({ id: item.id, product_id: item.product_id,
                             variant_id: item.variant_id, quantity: item.fulfillable_quantity })
      end
      raise @order unless order.success?

      find_location
    end

    def find_location
      variants = retrieve_variants
      variant = ShopifyAPI::Variant.find(variants[0])
      inventory_lvl = ShopifyAPI::InventoryLevel.find(:all, params: { inventory_item_ids: variant.inventory_item_id })[0]
      inventory_lvl.attributes[:location_id]
    end

    def retrieve_variants
      variant_ids = []
      @line_items.each { |item| variant_ids.append(item[:variant_id]) }
      variant_ids
    end

    def fill_fulfillment(tracking_info)
      @fulfillment = ShopifyAPI::Fulfillment.new
      @fulfillment.attributes.merge!({ old_location_id: @order_items[0].origin_location.id,
                                       location_id: find_location,
                                       tracking_number: tracking_info[:tracking_number],
                                       tracking_url: tracking_info[:tracking_url],
                                       tracking_company: tracking_info[:tracking_company],
                                       line_items: @line_items })
      @fulfillment.order_id = @order.data[:order].id
    end

    def save_fulfillment
      @fulfillment.save
    end

    def initiate_api(login_info)
      shop_url = "https://#{login_info[:api_key]}:#{login_info[:password]}@#{login_info[:shop_name]}.myshopify.com"
      ShopifyAPI::Base.site = shop_url
      ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning
    end
  end
end
