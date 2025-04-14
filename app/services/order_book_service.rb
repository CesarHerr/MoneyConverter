# frozen_string_literal: true

# Itera sobre las ofertas del libro de órdenes
# Multiplica cada cantidad disponible por su precio correspondiente
# Continuar procesando niveles de precios hasta cumplir el monto requerido
# Devuelve información si hay o no suficiente cantidad en el mercado
class OrderBookService
  def self.calculate_max_amount(order_book_entries, amount, market, is_buying)
    new(order_book_entries, amount, market, is_buying).calculate
  end

  def initialize(order_book_entries, amount, market, is_buying)
    @entries = order_book_entries
    @amount = amount
    @market = market
    @is_buying = is_buying
    @total_cost = 0.0
    @remaining = amount
  end

  # calculate is the main method that processes the order book entries
  def calculate
    log_start

    sorted_entries.each do |entry|
      price, available = entry.map(&:to_f)
      break if @remaining <= 0

      @is_buying ? process_buy(price, available) : process_sell(price, available)
    end

    result
  rescue StandardError => e
    log_error(e)
    { error: e.message }
  end

  private

  def log_start
    Rails.logger.info "[calculate_max_amount] Inicio cálculo - #{@market} - #{@is_buying ? 'Compra' : 'Venta'} - Monto: #{@amount}"
  end

  # sorted_entries sorts the order book entries based on the price
  def sorted_entries
    @entries.sort_by { |entry| @is_buying ? entry[0].to_f : -entry[0].to_f }
  end

  # process_buy processes the buy orders
  def process_buy(price, available)
    max_affordable = @remaining / price
    if max_affordable <= available
      @total_cost += max_affordable
      @remaining = 0
    else
      @total_cost += available
      @remaining -= available * price
    end
  end

  # process_sell processes the sell orders
  def process_sell(price, available)
    if available >= @remaining
      @total_cost += @remaining * price
      @remaining = 0
    else
      @total_cost += available * price
      @remaining -= available
    end
  end

  def result
    {
      total_cost: @total_cost.round(2),
      remaining_amount: @remaining.round(2),
      complete: @remaining.zero?
    }
  end

  def log_error(e)
    Rails.logger.error "[OrderBookService] Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
