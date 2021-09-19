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
      fill_fulfillment
      save_fulfillment
    rescue StandardError => e
      handling = handle_error(e)
      OpenStruct.new('success?' => false, 'error_code' => handling[:code], 'error_message' => handling[:message],
                     'data' => handling[:data])
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { fulfillment: fulfillment })
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
    end

    def handle_error(err)
      if err.instance_of?(SyncOrderError)
        { 'code' => '4XX', 'message' => 'Error on order.', data: { order: order } }
      elsif err.instance_of?(AlreadyFulfilledError)
        { 'code' => '422', 'message' => 'Order is already fulfilled.', data: { order: order } }
      elsif err.instance_of?(ActiveResource::ResourceNotFound)
        error_message = 'Error code 404 Not Found; check the id of the order,'
        error_message += ' verify that no variant was removed, or no location vas moved.'
        { code: '404', message: error_message, data: nil }
      else
        { code: '???', message: 'Unhandled error.', data: { error: err } }
      end
    end
  end
end
