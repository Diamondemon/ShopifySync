require 'awesome_print'
require 'shopify_api'

API_KEY = ''
PASSWORD = ''
SHOP_NAME = ''

shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
ShopifyAPI::Base.site = shop_url
ShopifyAPI::Base.api_version = '2021-10' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning

shop = ShopifyAPI::Shop.current

products = ShopifyAPI::Product.find(:all, params: { limit: 50 })

ap products
