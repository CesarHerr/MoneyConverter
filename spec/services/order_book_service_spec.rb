# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderBookService, type: :service do
  describe '.calculate_max_amount' do
    let(:order_book_entries) do
      [
        [1000, 2.0], # Precio: 1000 CLP por BTC, Cantidad: 2 BTC
        [1100, 3.0]  # Precio: 1100 CLP por BTC, Cantidad: 3 BTC
      ]
    end

    context 'when buying cryptocurrency' do
      let(:amount) { 2000 } # Comprar con 2000 CLP
      let(:is_buying) { true }

      it 'calculates total cost and remaining amount correctly for buying', :aggregate_failures do
        result = described_class.calculate_max_amount(order_book_entries, amount, 'btc-clp', is_buying)

        expect(result[:total_cost]).to eq(2.0) # Compramdos 2 BTC con 2000 CLP
        expect(result[:remaining_amount]).to eq(0) # Ya no queda dinero por gastar
        expect(result[:complete]).to be_truthy # Compra completada
      end
    end

    context 'when selling cryptocurrency' do
      let(:amount) { 2.0 } # Vender 2 BTC
      let(:is_buying) { false }

      it 'calculates total cost and remaining amount correctly for selling', :aggregate_failures do
        result = described_class.calculate_max_amount(order_book_entries, amount, 'btc-clp', is_buying)

        expect(result[:total_cost]).to eq(2200.0) # Recibe 2200 CLP al vender 2 BTC
        expect(result[:remaining_amount]).to eq(0) # Ya no queda BTC por vender
        expect(result[:complete]).to be_truthy # Venta completada
      end
    end
  end
end
