# frozen_string_literal: true

require './get_order_service'
require './get_orders_service'

ap ShopifySync::GetOrdersService.call.data[:orders][0].id

# ap ShopifySync::GetOrderService.call(4_108_548_604_055).success?
