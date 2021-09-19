# frozen_string_literal: true

require 'shopify_api'
require 'ostruct'
require './connection_service'
require './exceptions'

module ShopifySync
  # Service to fulfill orders in the shop
  class SetTrackingNumberService
    attr_accessor :order, :fulfillments, :tracking_info, :shopify_order_id, :shopify_login_info, :line_items,
                  :location_ids, :locations

    def self.call(params)
      new(params).call
    end

    def call
      pull_order_from_shopify
      fill_fulfillments
      save_fulfillments
    rescue RuntimeError, ActiveResource::ClientError => e
      handling = handle_error(e)
      OpenStruct.new('success?' => false, 'error_code' => handling[:code], 'error_message' => handling[:message],
                     'data' => handling[:data])
    else
      OpenStruct.new('success?' => true, 'error_code' => nil, 'data' => { fulfillments: fulfillments })
    end

    private

    def initialize(params)
      @tracking_info = params[:tracking_info]
      @shopify_login_info = params[:login_info]
      @shopify_order_id = params[:order_id]
      @location_ids = params[:location_ids] || :all
      initiate_shopify_api
    end

    def initiate_shopify_api
      ConnectionService.call(shopify_login_info)
    end

    def pull_order_from_shopify
      @order = GetExtraOrderService.call({ login_info: shopify_login_info, order_id: shopify_order_id })
      @locations = order.data[:locations]
      raise SyncOrderError unless order.success?

      raise AlreadyFulfilledError if order.data[:order].fulfillment_status == 'fulfilled'
    end

    def fill_fulfillments
      @fulfillments = []
      if location_ids == :all
        locations.each_key { |location_id| fill_fulfillment(location_id) }
      else
        location_ids.each { |location_id| fill_fulfillment(location_id) }
      end
    end

    def fill_fulfillment(location_id)
      fulfillment = ShopifyAPI::Fulfillment.new
      fulfillment.attributes.merge!({ location_id: location_id,
                                      tracking_number: tracking_info[:tracking_number],
                                      tracking_url: tracking_info[:tracking_url],
                                      tracking_company: tracking_info[:tracking_company],
                                      line_items: @locations[location_id] })
      fulfillment.order_id = order.data[:order].id
      @fulfillments << fulfillment
    end

    def save_fulfillments
      @fulfillments.each do |fulfillment|
        fulfillment.attributes[:line_items].nil? ? @fulfillments.delete(fulfillment) : fulfillment.save
      end
    end

    def handle_error(err)
      if err.instance_of?(SyncOrderError)
        { 'code' => '4XX', 'message' => 'Error on order.', data: { order: order } }
      elsif err.instance_of?(AlreadyFulfilledError)
        { 'code' => '422', 'message' => 'Order is already fulfilled.', data: { order: order } }
      elsif err.instance_of?(ActiveResource::ResourceNotFound)
        error_message = 'Error code 404 Not Found; check the id of the order, verify that no variant was removed,'
        { code: '404', message: "#{error_message} or no location vas moved.", data: nil }
      else
        { code: '4XX', message: 'Unhandled error.', data: { error: err } }
      end
    end
  end
end
