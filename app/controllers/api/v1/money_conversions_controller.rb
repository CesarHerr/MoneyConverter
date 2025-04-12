class Api::V1::MoneyConversionsController < ApplicationController
  require "net/http"
  require "json"

  # POST /api/v1/money_conversions
  # This action receives the parameters for the conversion and processes them
  def create
    Rails.logger.info "Params recibidos: #{params.inspect}"
    # Criptocurrencies to be used as intermediaries for conversion
    intermediaries = [ "BTC", "ETH", "LTC" ]

    best_conversion = search_intermediaries (intermediaries)

    get_response(best_conversion)
  end

  private

  # This method is used to search for the best conversion using intermediaries
  def search_intermediaries(intermediaries, best_conversion = nil)
    origin = create_params[:origin]
    destination = create_params[:destination]
    amount = create_params[:amount].to_f

    Rails.logger.info "Inicio de busqueda mejor conversión para /n
                    Moneda origen: #{origin} a Moneda destino: #{destination} con monto: #{amount}"
    intermediaries.each do |crypto|
      # Fetch the price of the origin currency
      buy_price = BudaPriceService.fetch_last_price("#{crypto}-#{origin}")
      next unless buy_price

      crypto_amount = amount / buy_price

      # Fetch the price of the destination currency
      sell_price = BudaPriceService.fetch_last_price("#{crypto}-#{destination}")
      next unless sell_price

      final_amount = crypto_amount * sell_price

      # Check if the conversion is profitable
      # If it's the first conversion or if the final amount is greater than the best conversion
      if best_conversion.nil? || final_amount > best_conversion[:amount]
        best_conversion = {
          amount: final_amount,
          intermediary: crypto
        }
        Rails.logger.info "Se ha encontrado mejor conversion : #{best_conversion}"
      end

      best_conversion
    end
  end

  # This method is used to render the response in JSON format
  def get_response(best_conversion)
    puts "best conversion: #{best_conversion}"
    if best_conversion
      render json: {
        amount: best_conversion[:amount],
        intermediary: best_conversion[:intermediary]
      }
    else
      render json: { error: "No se pudo realizar la conversión" }, status: :unprocessable_entity
    end
  end

  # Strong parameters to prevent mass assignment vulnerabilities
  def create_params
    params.permit(:origin, :destination, :amount)
  end
end
