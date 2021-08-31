# frozen_string_literal: true

require './get_order_service'
require './get_orders_service'
require './set_tracking_number_service'

# ShopifySync::GetOrdersService.call.data[:orders][0].id

# ap ShopifySync::GetOrderService.call(4_108_548_604_055).success?

ap ShopifySync::SetTrackingNumberService.call({ order_id: 4_108_548_604_055,
                                                tracking_number: 1,
                                                tracking_url: 'https://laposte.net/',
                                                tracking_company: 'La Poste' })
