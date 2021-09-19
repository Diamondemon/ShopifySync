# frozen_string_literal: true

require 'awesome_print'
require './shopify_sync'

API_KEY = '59beb17eeaad18110aed3aac6aaafd9d' # Wrong => Error 403
PASSWORD = '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' # Wrong => Error 401
SHOP_NAME = 'jmhsoft' # Wrong => Error 404

params = { login_info: { api_key: API_KEY, password: PASSWORD, shop_name: SHOP_NAME }, params: { limit: 50 } }

# get all order ids
id_list = []
ShopifySync::GetOrdersService.call(params).data[:orders].each { |order| id_list.append(order.id) }

# display the first order found
ap ShopifySync::GetExtraOrderService.call(params.merge({ order_id: id_list[0] }))

# fulfill all pending orders
=begin tracking_number = 1

id_list.each do |id|
  ap ShopifySync::SetTrackingNumberService.call(params.merge({ order_id: id,
                                                               tracking_info: { tracking_number: tracking_number,
                                                                                tracking_url: 'https://laposte.net/',
                                                                                tracking_company: 'La Poste' } }))
  tracking_number += 1
end
=end
