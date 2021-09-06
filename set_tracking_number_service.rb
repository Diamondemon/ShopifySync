# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'
require './exceptions'

module ShopifySync
  # Service to fulfill orders in the shop
  class SetTrackingNumberService
    attr_accessor :order, :fulfillment, :tracking_info, :shopify_order_id, :shopify_login_info, :line_items

    def self.call(params)
      new(params).call
    end

    def call
      pull_order_from_shopify
    rescue SyncOrderError
      OpenStruct.new('success?' => false, 'error_code' => '4XX', 'error_message' => 'Error on order.',
                     'data' => { order: order })
    rescue AlreadyFulfilledError
      OpenStruct.new('success?' => false, 'error_code' => '001', 'error_message' => 'Order is already fulfilled.',
                     'data' => { order: order })
    else
      fill_fulfillment
      save_fulfillment
    end

    private

    def initialize(params)
      @tracking_info = params[:tracking_info]
      @shopify_login_info = params[:login_info]
      @shopify_order_id = params[:order_id]
      initiate_shopify_api
    end

    def initiate_shopify_api
      ConnectionService.call(shopify_login_info)
    end

    def pull_order_from_shopify
      @order = GetOrderService.call({ login_info: shopify_login_info, order_id: shopify_order_id })
      raise SyncOrderError unless @order.success?

      raise AlreadyFulfilledError if @order.data[:order].fulfillment_status == 'fulfilled'

      fill_line_items
    end

    def fill_line_items
      @order_items = @order.data[:order].line_items
      @line_items = []
      @order_items.each do |item|
        @line_items.append({ id: item.id, product_id: item.product_id,
                             variant_id: item.variant_id, quantity: item.fulfillable_quantity })
      end
    end

    def find_location
      variants = retrieve_variants
      variant = ShopifyAPI::Variant.find(variants[0])
      invent_lvl = ShopifyAPI::InventoryLevel.find(:all, params: { inventory_item_ids: variant.inventory_item_id })[0]
      invent_lvl.attributes[:location_id]
    end

    def retrieve_variants
      variant_ids = []
      @line_items.each { |item| variant_ids.append(item[:variant_id]) }
      variant_ids
    end

    def fill_fulfillment
      @fulfillment = ShopifyAPI::Fulfillment.new
      @fulfillment.attributes.merge!({ location_id: find_location,
                                       tracking_number: tracking_info[:tracking_number],
                                       tracking_url: tracking_info[:tracking_url],
                                       tracking_company: tracking_info[:tracking_company],
                                       line_items: @line_items })
      @fulfillment.order_id = @order.data[:order].id
    end

    def save_fulfillment
      @fulfillment.save
    rescue ActiveResource::ResourceNotFound
      error_code = 'Error code 404 Not Found; check the id of the order,'
      error_code += ' verify that no variant was removed, or no location vas moved.'
      OpenStruct.new('success?' => false, 'error_code' => error_code, 'data' => nil)
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { fulfillment: @fulfillment })
    end
  end
end
