# frozen_string_literal: true

require 'awesome_print'
require './shopify_sync'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d' # Wrong => Error 403
PASSWORD = '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' # Wrong => Error 401
SHOP_NAME = 'jmhsoft' # Wrong => Error 404

params = { login_info: { api_key: API_KEY, password: PASSWORD, shop_name: SHOP_NAME }, params: { limit: 50 } }

ap ShopifySync::GetOrdersService.call(params)

# ap ShopifySync::GetOrderService.call(params.merge({ order_id: 4_118_688_399_511 })).data[:order].attributes

=begin
ap ShopifySync::SetTrackingNumberService.call(params.merge({ order_id: 4_110_797_930_647,
                                                             tracking_info: { tracking_number: 4,
                                                                              tracking_url: 'https://laposte.net/',
                                                                              tracking_company: 'La Poste' } }))
=end
