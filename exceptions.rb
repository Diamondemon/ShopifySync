# frozen_string_literal: true

module ShopifySync
  # Error when something bad happens when retrieving orders
  class SyncOrderError < RuntimeError
  end

  # Error when the order is already fulfilled
  class AlreadyFulfilledError < RuntimeError
  end
end
