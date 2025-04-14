# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiBudaService, type: :service do
  describe '.order_book' do
    let(:mock_response_order_book) do
      instance_double(
        Net::HTTPResponse,
        body: {
          order_book: {
            asks: [[30_000, 0.1], [31_000, 0.2]],
            bids: [[29_000, 0.05], [28_500, 0.1]]
          }
        }.to_json,
        is_a?: ->(klass) { klass == Net::HTTPSuccess }
      )
    end

    before do
      allow(Net::HTTP).to receive(:get_response).and_return(mock_response_order_book)
    end

    it 'fetches the order book successfully', :aggregate_failures do
      result = described_class.order_book('btc-clp')
      expect(result['asks']).to eq([[30_000, 0.1], [31_000, 0.2]]) # Verificar las ofertas de venta
      expect(result['bids']).to eq([[29_000, 0.05], [28_500, 0.1]]) # Verificar las ofertas de compra
    end
  end
end
