# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MoneyConversions', type: :request do
  describe 'POST /api/v1/money_conversions' do
    let(:valid_params) { { origin: 'clp', destination: 'pen', amount: 10_000 } }

    before do
      allow(ApiBudaService).to receive(:fetch_markets_ids).and_return(%w[btc-clp btc-pen])
      allow(ApiBudaService).to receive(:order_book).with('btc-clp').and_return({
                                                                                 'asks' => [['0.0001', '1000000']]
                                                                               })
      allow(ApiBudaService).to receive(:order_book).with('btc-pen').and_return({
                                                                                 'bids' => [%w[100000 1]]
                                                                               })

      allow(OrderBookService).to receive(:calculate_max_amount).with(
        [['0.0001', '1000000']],
        10_000,
        'btc-clp',
        true
      ).and_return({ total_cost: 1, complete: true })

      allow(OrderBookService).to receive(:calculate_max_amount).with(
        [%w[100000 1]],
        1,
        'btc-pen', # Cambiar 'btc-clp' a 'btc-pen' para que coincida con el test
        false
      ).and_return({ total_cost: 100, complete: true })
    end

    it 'returns a successful conversion with intermediary' do # rubocop:disable RSpec/MultipleExpectations
      post '/api/v1/money_conversions', params: valid_params

      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json['amount']).to eq(100)
      expect(json['intermediary']).to eq('btc')
    end

    it 'returns error if parameters are invalid' do
      post '/api/v1/money_conversions', params: { origin: '', destination: '', amount: -1 }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns error if no markets are found' do
      allow(ApiBudaService).to receive(:fetch_markets_ids).and_return(nil)
      post '/api/v1/money_conversions', params: valid_params
      expect(response).to have_http_status(422)
    end

    it 'returns error if no intermediaries are found' do
      allow(ApiBudaService).to receive(:fetch_markets_ids).and_return(['eth-ars'])
      post '/api/v1/money_conversions', params: valid_params
      expect(response).to have_http_status(422)
    end

    it 'returns error if no valid conversion is found' do
      allow(OrderBookService).to receive(:calculate_max_amount).and_return({ total_cost: 0, complete: false })
      post '/api/v1/money_conversions', params: valid_params
      expect(response).to have_http_status(422)
    end
  end
end
