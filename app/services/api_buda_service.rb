# frozen_string_literal: true

# This service class is responsible for interacting with the Buda.com API
# to fetch market data such as last prices and order books.
#
# It provides methods to:
# - Fetch the last price of a given market
# - Fetch the IDs of all markets available in Buda.com
# - Fetch the order book for a given market
class ApiBudaService
  require 'net/http'
  require 'json'

  BASE_URL = 'https://www.buda.com/api/v2/markets'

  class << self
    def fetch_last_price(market)
      path = "#{BASE_URL}/#{market.downcase}/ticker"
      data = get_json(path)
      data&.dig('ticker', 'last_price', 0)&.to_f
    end

    def fetch_markets_ids
      data = get_json(BASE_URL)
      data&.fetch('markets', [])&.pluck('id')
    end

    def order_book(market_id)
      path = "#{BASE_URL}/#{market_id.downcase}/order_book"
      get_json(path)&.fetch('order_book', nil)
    end

    private

    def get_json(url)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error "[ApiBudaService] HTTP Error for #{url}: #{response.code} #{response.message}"
      nil
    rescue StandardError => e
      log_error(url, e)
      nil
    end

    def log_error(url, exception)
      Rails.logger.error "[ApiBudaService] Exception for #{url}: #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
    end
  end
end
