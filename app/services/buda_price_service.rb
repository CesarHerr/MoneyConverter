class BudaPriceService
  require "net/http"
  require "json"

  BASE_URL = "https://api.buda.com/api/v2/markets/"

  def self.fetch_last_price(market)
    url = URI("#{BASE_URL}#{market.downcase}/ticker")
    response = Net::HTTP.get_response(url)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data["ticker"]["last_price"][0].to_f
  rescue
    nil
  end
end
