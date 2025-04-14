# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'MoneyConversions API', swagger_doc: 'v1/swagger.yaml', type: :request do
  path '/api/v1/money_conversions' do
    post 'Convierte monedas usando un intermediario' do
      tags 'MoneyConversions'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :conversion, in: :body, schema: {
        type: :object,
        properties: {
          origin: { type: :string },
          destination: { type: :string },
          amount: { type: :number }
        },
        required: %w[origin destination amount]
      }

      response '200', 'Conversión exitosa' do
        let(:conversion) { { origin: 'CLP', destination: 'PEN', amount: 10_000 } }
        run_test!
      end

      response '400', 'Parámetros inválidos' do
        let(:conversion) { { origin: '', destination: '', amount: nil } }
        run_test!
      end

      response '422', 'Conversión fallida' do
        let(:conversion) { { origin: 'clp', destination: 'cop', amount: 99_999 } }
        run_test!
      end
    end
  end
end
