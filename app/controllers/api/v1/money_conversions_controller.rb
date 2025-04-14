# frozen_string_literal: true

module Api
  module V1
    # This controller handles money conversion requests.
    # It interacts with the ApiBudaService to fetch market data and uses
    # the OrderBookService to calculate the best conversion rates.
    class MoneyConversionsController < ApplicationController
      require 'net/http'
      require 'json'

      # This action handles the conversion of money from one currency to another.
      def create
        return render json: { error: 'Parámetros inválidos' }, status: :bad_request if invalid_params?

        log_info('MoneyConversions#create', "Params recibidos: #{create_params.to_h}")

        market_ids = fetch_market_ids
        return render_conversion_error if market_ids.blank?

        intermediaries = find_intermediaries(market_ids)
        return render_conversion_error if intermediaries.blank?

        best_conversion = find_best_conversion(intermediaries)

        render_conversion_response(best_conversion)
      rescue StandardError => e
        log_error('MoneyConversions#create', e)
        render_conversion_error
      end

      private

      def invalid_params?
        create_params[:origin].blank? || create_params[:destination].blank? || create_params[:amount].to_f <= 0
      end

      # Fetches the market IDs from the Buda API.
      def fetch_market_ids
        ApiBudaService.fetch_markets_ids
      rescue StandardError => e
        log_error('MoneyConversions#fetch_market_ids', e)
        nil
      end

      # fetch_market_ids fetches the market IDs from the Buda API.
      def find_intermediaries(markets)
        origin = create_params[:origin]
        destination = create_params[:destination]

        markets.select { |market| market.include?(origin) || market.include?(destination) }
               .filter_map do |market|
                 market.split('-').detect { |currency| currency != origin && currency != destination }
               end.uniq
      end

      def find_best_conversion(intermediaries)
        origin = create_params[:origin]
        destination = create_params[:destination]
        amount = create_params[:amount].to_f
        best_conversion = nil

        log_info('MoneyConversions#find_best_conversion',
                 "Buscando mejor conversión de #{origin} a #{destination} con #{amount}")

        intermediaries.each do |intermediary|
          intermediate_amount = simulate_conversion_step("#{intermediary}-#{origin}", amount, :asks, true)
          next unless intermediate_amount[:complete]

          final_amount = simulate_conversion_step("#{intermediary}-#{destination}", intermediate_amount[:total_cost],
                                                  :bids, false)
          next unless final_amount[:complete]

          log_info('MoneyConversions#find_best_conversion',
                   "Intermediario: #{intermediary}, Monto final: #{final_amount[:total_cost]}")

          next unless best_conversion.nil? || final_amount[:total_cost] > best_conversion[:amount]

          best_conversion = {
            amount: final_amount[:total_cost],
            intermediary: intermediary
          }
          log_info('MoneyConversions#find_best_conversion', "Nueva mejor conversión encontrada: #{best_conversion}")
        end

        best_conversion
      rescue StandardError => e
        log_error('MoneyConversions#find_best_conversion', e)
        nil
      end

      def simulate_conversion_step(market_id, amount, order_type, reverse)
        order_book = ApiBudaService.order_book(market_id)
        return {} if order_book.blank?

        OrderBookService.calculate_max_amount(
          order_book[order_type.to_s],
          amount,
          market_id,
          reverse
        )
      rescue StandardError => e
        log_error("MoneyConversions#simulate_conversion_step:#{market_id}", e)
        {}
      end

      def render_conversion_response(best_conversion)
        if best_conversion.present?
          render json: best_conversion, status: :ok
        else
          render_conversion_error
        end
      end

      def render_conversion_error
        render json: { error: 'No se pudo realizar la conversión' }, status: :unprocessable_entity
      end

      def create_params
        params.permit(:origin, :destination, :amount)
      end

      def log_info(context, message)
        Rails.logger.info "[#{context}] #{message}"
      end

      def log_error(context, error)
        Rails.logger.error "[#{context}] Error: #{error.message}"
        Rails.logger.error error.backtrace.join("\n")
      end
    end
  end
end
