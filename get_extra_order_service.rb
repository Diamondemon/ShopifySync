# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'
require 'awesome_print'

module ShopifySync
  # Service to retrieve the specified order, its line items and the locations
  class GetExtraOrderService < GetOrderService
    attr_accessor :locations, :line_items

    def call
      pull_order_from_shopify
      fill_line_items
      retrieve_variants_and_locations
    rescue ActiveResource::ClientError => e
      error_details = handle_error(e)
      OpenStruct.new('success?' => false, 'error_code' => error_details[:code],
                     'error_message' => error_details[:message], 'data' => { error: e })
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { order: shopify_order,
                                                                          line_items: line_items,
                                                                          locations: locations })
    end

    private

    def fill_line_items
      @order_items = shopify_order.line_items
      @line_items = []
      @order_items.each do |item|
        @line_items.append({ id: item.id, product_id: item.product_id,
                             variant_id: item.variant_id, quantity: item.fulfillable_quantity })
      end
    end

    def retrieve_variants_and_locations
      @locations = []
      @line_items.each do |item|
        variant = ShopifyAPI::Variant.find(item[:variant_id])
        invent_lvls = ShopifyAPI::InventoryLevel.find(:all, params: { inventory_item_ids: variant.inventory_item_id })
        invent_lvls.each do |invent_lvl|
          @locations << invent_lvl.attributes[:location_id]
          item[:location_id] = invent_lvl.attributes[:location_id]
        end
      end
      @locations.sort!.uniq!
    end
  end
end
