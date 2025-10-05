# frozen_string_literal: true

RSpec.describe A2A::Types::URI do
  describe '.call' do
    context 'when given a String' do
      it 'converts the String to a URI' do
        result = described_class.call('https://example.com/path')

        expect(result).to eq(URI('https://example.com/path'))
      end
    end

    context 'when given a URI' do
      it 'returns the URI' do
        uri = URI('https://example.com/path')
        result = described_class.call(uri)

        expect(result).to eq(uri)
      end
    end

    context 'when given an invalid type' do
      it 'raises an ArgumentError' do
        expect { described_class.call(123) }.to raise_error(
          Dry::Types::CoercionError, /Expected String or URI, got Integer/
        )
      end
    end
  end
end
