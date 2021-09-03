# frozen_string_literal: true

require './get_order_service'
require './get_orders_service'
require './set_tracking_number_service'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d'
PASSWORD = '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'
SHOP_NAME = 'jmhsoft'

params = { login_info: { api_key: API_KEY, password: PASSWORD, shop_name: SHOP_NAME } }

# ap ShopifySync::GetOrdersService.call(params).data[:orders][0].id

# ap ShopifySync::GetOrderService.call(params.merge({ order_id: 4_108_548_604_055 })).data[:order].attributes
# ap ShopifySync::GetOrderService.call(params.merge({ order_id: 4_118_688_399_511 })).data[:order].attributes

ap ShopifySync::SetTrackingNumberService.call(params.merge({ order_id: 4_118_688_399_511,
                                                             tracking_info: { tracking_number: 1,
                                                                              tracking_url: 'https://laposte.net/',
                                                                              tracking_company: 'La Poste' } }))
