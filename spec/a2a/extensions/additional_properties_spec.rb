# frozen_string_literal: true

RSpec.describe A2A::Extensions::AdditionalProperties do
  let(:test_class) do
    Class.new(Dry::Struct) do
      include A2A::Extensions::AdditionalProperties

      attribute :firstName, A2A::Types::Strict::String
      attribute :age, A2A::Types::Strict::Integer
    end
  end

  describe '.new' do
    it 'initializes with exact schema attributes' do
      instance = test_class.new(firstName: 'Test', age: 30)

      expect(instance).to be_a(test_class)
      expect(instance.firstName).to eq('Test')
      expect(instance.age).to eq(30)
      expect(instance.additional_properties).to be_empty
    end

    it 'recognizes schema keys regardless of case' do
      instance = test_class.new(firstName: 'Test', 'Age' => 30)

      expect(instance).to be_a(test_class)
      expect(instance.firstName).to eq('Test')
      expect(instance.age).to eq(30)
      expect(instance.additional_properties).to be_empty
    end

    it 'handles additional properties' do
      instance = test_class.new(
        firstName: 'Test',
        age: 30,
        emailAddress: 'test@example.com',
        homeAddress: '123 Main St'
      )

      expect(instance).to be_a(test_class)
      expect(instance.firstName).to eq('Test')
      expect(instance.age).to eq(30)
      expect(instance.email_address).to eq('test@example.com')
      expect(instance.home_address).to eq('123 Main St')
      expect(instance.additional_properties).to eq(
        email_address: 'test@example.com',
        home_address: '123 Main St'
      )
    end
  end

  describe 'instance methods' do
    let(:instance) do
      test_class.new(
        firstName: 'Test',
        age: 30,
        email: 'test@example.com',
        address: '123 Main St'
      )
    end

    describe '#method_missing' do
      it 'returns the additional property value if present' do
        expect(instance.email).to eq('test@example.com')
        expect(instance.address).to eq('123 Main St')
      end

      it 'raises NoMethodError if additional property is not present' do
        expect { instance.phone }.to raise_error(NoMethodError)
      end
    end

    describe '#respond_to_missing?' do
      it 'returns true if additional property is present' do
        expect(instance.respond_to?(:email)).to be true
      end

      it 'returns false if additional property is not present' do
        expect(instance.respond_to?(:phone)).to be false
      end
    end

    describe '#to_h' do
      it 'returns a hash with both schema and additional properties' do
        expect(instance.to_h).to eq(
          firstName: 'Test',
          age: 30,
          email: 'test@example.com',
          address: '123 Main St'
        )
      end
    end

    describe '#camelize' do
      it 'camelizes hash keys' do
        result = instance.camelize({ first_name: 'John', last_name: 'Doe' })
        expect(result).to eq({ firstName: 'John', lastName: 'Doe' })
      end

      it 'camelizes nested hash keys' do
        result = instance.camelize({ user_data: { first_name: 'John', last_name: 'Doe' } })
        expect(result).to eq({ userData: { firstName: 'John', lastName: 'Doe' } })
      end

      it 'camelizes hash keys in arrays' do
        result = instance.camelize([{ first_name: 'John' }, { last_name: 'Doe' }])
        expect(result).to eq([{ firstName: 'John' }, { lastName: 'Doe' }])
      end

      it 'returns non-hash/array values unchanged' do
        expect(instance.camelize('string')).to eq('string')
        expect(instance.camelize(123)).to eq(123)
        expect(instance.camelize(true)).to be(true)
      end
    end
  end
end
