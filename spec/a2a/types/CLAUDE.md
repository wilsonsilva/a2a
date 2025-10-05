# Type Test Standards

This document describes the structure, conventions, and patterns for writing RSpec tests for A2A type classes (data structures in `lib/a2a/types/`).

## File Structure

### 1. File Header
```ruby
# frozen_string_literal: true

RSpec.describe A2A::TypeName do
  # ...
end
```

### 2. Top-Level Structure
Every type test file MUST include these four sections in order:
1. `.new` - Testing initialization/construction
2. `#to_h` - Testing hash conversion
3. `#to_json` - Testing JSON serialization
4. `.from_json` - Testing JSON deserialization

## Section 1: `.new` - Initialization Tests

### Required Contexts

#### Context: "when given attributes with snake case keys"
Tests basic initialization with snake_case attributes from factory.

```ruby
context 'when given attributes with snake case keys' do
  # Attributes defined in the factory are snake case
  let(:type_name_attributes) { attributes_for(:factory_name) }

  it 'initializes a[n] [type description]' do
    instance = described_class.new(type_name_attributes)

    expect(instance).to be_a(described_class)
  end
end
```

**Rules:**
- Use `attributes_for(:factory_name)` from FactoryBot
- Include inline comment explaining factory uses snake case
- Let block named with `_attributes` suffix
- Use indefinite article "a" or "an" appropriately in test description

#### Context: "when given attributes with camel case keys"
Tests that the type accepts camelCase keys (tests JSONDeserialization extension).

**When to include:** Include if the type has ANY multi-word attributes that differ between snake_case and camelCase.

```ruby
context 'when given attributes with camel case keys' do
  # Uses the snake key attributes from the factory and overrides some with camel case keys
  let(:type_name_attributes) do
    attributes_for(:factory_name).merge(
      camelCaseKey: 'value',
      anotherCamelKey: 'value'
    )
  end

  it 'initializes a[n] [type description]' do
    instance = described_class.new(type_name_attributes)

    expect(instance).to be_a(described_class)
  end
end
```

**Rules:**
- Include inline comment about merging snake and camel case
- Merge camelCase keys with factory attributes using `.merge()`
- Override at least 2-3 representative multi-word attributes

#### Context: "when the optional attributes are missing"
Tests that optional attributes properly default to nil or their default values.

**When to include:** Include if the type has ANY optional attributes.

```ruby
context 'when the optional attributes are missing' do
  let(:type_name_attributes) do
    attributes_for(:factory_name).except(
      :optional_field_1,
      :optional_field_2,
      :optional_field_3
    )
  end

  it 'initializes a[n] [type description]', :aggregate_failures do
    instance = described_class.new(type_name_attributes)

    expect(instance).to be_a(described_class)
    expect(instance.optional_field_1).to be_nil
    expect(instance.optional_field_2).to be_nil
    expect(instance.optional_field_3).to be_nil
  end
end
```

**Rules:**
- Use `.except()` to remove optional attributes
- Use `:aggregate_failures` metadata
- First expectation checks instance type
- Subsequent expectations check each optional field is nil
- List ALL optional attributes

#### Context: "when the default attributes are missing"
Tests that attributes with default values (typically `false` for booleans) work correctly.

**When to include:** Include ONLY if the type has attributes with non-nil default values (e.g., `default: false`).

```ruby
context 'when the default attributes are missing' do
  let(:type_name_attributes) do
    attributes_for(:factory_name).except(:field_with_default_1, :field_with_default_2)
  end

  it 'initializes [type description] with default attributes', :aggregate_failures do
    instance = described_class.new(type_name_attributes)

    expect(instance).to be_a(described_class)
    expect(instance.field_with_default_1).to be(false)
    expect(instance.field_with_default_2).to be(false)
  end
end
```

**Rules:**
- Use `.except()` to remove fields with defaults
- Use `:aggregate_failures` metadata
- Use `be(false)` or `be(true)` for boolean defaults
- Only test attributes that have explicit `default:` values in type definition

#### Context: "when the default attributes are overridden"
Tests that default values can be explicitly overridden.

**When to include:** Include ONLY if "when the default attributes are missing" context exists.

```ruby
context 'when the default attributes are overridden' do
  let(:type_name_attributes) do
    {
      required_field: 'value',
      field_with_default_1: true,
      field_with_default_2: true
    }
  end

  it 'initializes [type description] with overridden attributes', :aggregate_failures do
    instance = described_class.new(type_name_attributes)

    expect(instance).to be_a(described_class)
    expect(instance.field_with_default_1).to be(true)
    expect(instance.field_with_default_2).to be(true)
  end
end
```

#### Context: "when the required attributes are missing"
Tests validation error when required attributes are omitted.

```ruby
context 'when the required attributes are missing' do
  let(:type_name_attributes) do
    attributes_for(:factory_name).except(
      :required_field_1,
      :required_field_2,
      :required_field_3
    )
  end

  it 'raises an error' do
    expect { described_class.new(type_name_attributes) }.to raise_error(Dry::Struct::Error)
  end
end
```

**Rules:**
- Remove ALL required attributes using `.except()`
- Expect `Dry::Struct::Error` to be raised
- Use expect block syntax with braces

#### Context: Additional Validation Tests
Add additional validation contexts as needed for the specific type.

**Example:** Testing type constraints (e.g., enum values):
```ruby
context 'when type is incorrect' do
  let(:security_scheme_attributes) do
    {
      type: 'oauth2',
      open_id_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
    }
  end

  it 'raises an error' do
    expect { described_class.new(security_scheme_attributes) }.to raise_error(Dry::Struct::Error)
  end
end
```

## Section 2: `#to_h` - Hash Conversion Tests

Tests conversion of type instance to a Ruby hash with snake_case keys.

### Basic Structure

```ruby
describe '#to_h' do
  let(:instance_name) { build(:factory_name) }

  it 'converts the [type description] to a hash' do
    expect(instance_name.to_h).to eq(
      snake_case_field_1: 'value',
      snake_case_field_2: 123,
      nested_object: {
        nested_field: 'value'
      }
    )
  end
end
```

**Rules:**
- Use `build(:factory_name)` to create instance
- Let block named after the type (e.g., `agent_card`, `agent_skill`)
- Single expectation using `.eq()`
- Hash keys MUST be symbols in snake_case
- Include ALL attributes in expected hash, even nil values
- URI fields use `URI('...')` wrapper
- Nested objects expanded as nested hashes

### With Variants/Traits

If the type has factory traits representing different configurations:

```ruby
describe '#to_h' do
  context 'without extensions' do
    let(:agent_capabilities) { build(:agent_capabilities, :incapable) }

    it 'converts the agent capabilities to a hash' do
      expect(agent_capabilities.to_h).to eq(
        streaming: false,
        push_notifications: false,
        state_transition_history: false,
        extensions: nil
      )
    end
  end

  context 'with extensions' do
    let(:agent_capabilities) { build(:agent_capabilities, :with_extensions) }

    it 'converts the agent capabilities to a hash with extensions' do
      expect(agent_capabilities.to_h).to eq(
        streaming: true,
        push_notifications: true,
        state_transition_history: false,
        extensions: [
          {
            uri: URI('https://a2a.dev/extensions/custom-maps-v1'),
            description: 'Custom map styling',
            required: false,
            params: { 'maxLayers' => 10 }
          }
        ]
      )
    end
  end
end
```

**Rules:**
- Use contexts to test different variants
- Use factory traits (e.g., `:incapable`, `:with_extensions`)
- Test minimal and maximal configurations

## Section 3: `#to_json` - JSON Serialization Tests

Tests JSON serialization with both camelCase (default) and snake_case output.

### Structure

```ruby
describe '#to_json' do
  context 'when camel_case is true (default)' do
    let(:instance_name) { build(:factory_name) }

    it 'returns a JSON string with camel case keys' do
      expect(instance_name.to_json).to match_json(<<~JSON)
        {
          "camelCaseField": "value",
          "anotherField": 123
        }
      JSON
    end
  end

  context 'when camel_case is false' do
    let(:instance_name) { build(:factory_name) }

    it 'returns a JSON string with snake case keys' do
      expect(instance_name.to_json(camel_case: false)).to match_json(<<~JSON)
        {
          "snake_case_field": "value",
          "another_field": 123
        }
      JSON
    end
  end
end
```

**Rules:**
- Two contexts: default (camelCase) and explicit false (snake_case)
- Use `match_json()` matcher with heredoc JSON strings
- Use proper JSON formatting (2-space indent)
- String keys in JSON (not symbols)
- Multi-word keys in camelCase for default context
- Multi-word keys in snake_case when `camel_case: false`
- URI values as plain strings (not wrapped in `URI()`)
- Nested objects/arrays properly formatted
- Can use different factory traits in each context if helpful

### Hash Params Formatting

When including hash params (e.g., in extensions), keys in `params` follow the camelCase/snake_case of the overall output:

```ruby
# Default camelCase context
"params": {
  "maxLayers": 10,
  "supportedFormats": ["geojson", "kml"]
}

# snake_case context
"params": {
  "maxLayers": 10,
  "supportedFormats": ["geojson", "kml"]
}
```

## Section 4: `.from_json` - JSON Deserialization Tests

Tests parsing JSON strings (with camelCase keys) into Ruby objects.

### Structure

```ruby
describe '.from_json' do
  let(:json_string) do
    <<~JSON
      {
        "camelCaseField": "value",
        "nestedObject": {
          "nestedField": "value"
        }
      }
    JSON
  end

  it 'initializes a[n] [type description]' do
    instance = described_class.from_json(json_string)

    expect(instance).to be_a(described_class)
  end

  it 'parses camel_case_field' do
    instance = described_class.from_json(json_string)

    expect(instance.camel_case_field).to eq('value')
  end

  it 'parses nested_object' do
    instance = described_class.from_json(json_string)

    expect(instance.nested_object).to eq(
      A2A::NestedType.new(
        nested_field: 'value'
      )
    )
  end
end
```

**Rules:**
- First test: "initializes a[n] [type description]" - checks type
- Subsequent tests: "parses [snake_case_attribute_name]" - one per attribute
- Each test creates a NEW instance from JSON (no shared let block for instance)
- JSON string uses camelCase keys
- Expectations use snake_case attribute accessors
- URI fields expect `URI('...')` wrapper
- Nested objects expect full type initialization (e.g., `A2A::NestedType.new(...)`)
- Arrays of objects expect array of initialized objects
- Include ALL attributes, even optional ones present in JSON

### Nested Object Expectations

For complex nested objects:

```ruby
it 'parses provider' do
  agent_card = described_class.from_json(json_string)

  expect(agent_card.provider).to eq(
    A2A::AgentProvider.new(
      organization: 'Example Org',
      url: 'https://www.example.com'
    )
  )
end
```

### Array Expectations

For arrays of objects:

```ruby
it 'parses additional_interfaces' do
  agent_card = described_class.from_json(json_string)

  expect(agent_card.additional_interfaces).to eq(
    [
      A2A::AgentInterface.new(
        url: 'https://example.com/a2a/v1',
        transport: 'JSONRPC'
      ),
      A2A::AgentInterface.new(
        url: 'https://example.com/a2a/grpc',
        transport: 'GRPC'
      )
    ]
  )
end
```

### Hash Expectations

For hash attributes (e.g., security, params):

```ruby
it 'parses security' do
  agent_card = described_class.from_json(json_string)

  expect(agent_card.security).to eq(
    [
      { google: %w[openid profile email] }
    ]
  )
end
```

## General Conventions

### Naming
- Let block for attributes: `[type_name]_attributes`
- Let block for instance: `[type_name]` (singular)
- Use underscores in let block names, not hyphens

### Comments
- Add inline comments to explain factory usage: `# Attributes defined in the factory are snake case`
- Add inline comments when merging: `# Uses the snake key attributes from the factory and overrides some with camel case keys`

### Expectations
- Type checks: `be_a(described_class)`
- Nil checks: `be_nil`
- Boolean checks: `be(true)` or `be(false)` (not `eq(true)`)
- Equality: `eq(value)`
- JSON matching: `match_json(json_string)`
- Errors: `raise_error(Dry::Struct::Error)`

### RSpec Metadata
- Use `:aggregate_failures` when testing multiple expectations in one test
- Particularly for tests checking multiple nil values or multiple defaults

### Factory Usage
- `.new` tests: Use `attributes_for(:factory_name)` (returns hash)
- `#to_h` tests: Use `build(:factory_name)` (returns instance)
- `#to_json` tests: Use `build(:factory_name)` (returns instance)
- `.from_json` tests: Use `described_class.from_json(json_string)` (no factory)

## Complete Example Template

```ruby
# frozen_string_literal: true

RSpec.describe A2A::TypeName do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:type_name_attributes) { attributes_for(:factory_name) }

      it 'initializes a type name' do
        type_name = described_class.new(type_name_attributes)

        expect(type_name).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      # Uses the snake key attributes from the factory and overrides some with camel case keys
      let(:type_name_attributes) do
        attributes_for(:factory_name).merge(
          camelCaseKey: 'value'
        )
      end

      it 'initializes a type name' do
        type_name = described_class.new(type_name_attributes)

        expect(type_name).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:type_name_attributes) do
        attributes_for(:factory_name).except(:optional_field)
      end

      it 'initializes a type name', :aggregate_failures do
        type_name = described_class.new(type_name_attributes)

        expect(type_name).to be_a(described_class)
        expect(type_name.optional_field).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:type_name_attributes) do
        attributes_for(:factory_name).except(:required_field)
      end

      it 'raises an error' do
        expect { described_class.new(type_name_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:type_name) { build(:factory_name) }

    it 'converts the type name to a hash' do
      expect(type_name.to_h).to eq(
        required_field: 'value',
        optional_field: nil
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:type_name) { build(:factory_name) }

      it 'returns a JSON string with camel case keys' do
        expect(type_name.to_json).to match_json(<<~JSON)
          {
            "requiredField": "value",
            "optionalField": null
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:type_name) { build(:factory_name) }

      it 'returns a JSON string with snake case keys' do
        expect(type_name.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "required_field": "value",
            "optional_field": null
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "requiredField": "value"
        }
      JSON
    end

    it 'initializes a type name' do
      type_name = described_class.from_json(json_string)

      expect(type_name).to be_a(described_class)
    end

    it 'parses required_field' do
      type_name = described_class.from_json(json_string)

      expect(type_name.required_field).to eq('value')
    end
  end
end
```

## Checklist for Writing Type Tests

When writing a new type test, ensure you have:

- [ ] File header with `# frozen_string_literal: true`
- [ ] All four main sections: `.new`, `#to_h`, `#to_json`, `.from_json`
- [ ] `.new` section with:
  - [ ] "when given attributes with snake case keys" context
  - [ ] "when given attributes with camel case keys" context (if applicable)
  - [ ] "when the optional attributes are missing" context (if applicable)
  - [ ] "when the default attributes are missing" context (if applicable)
  - [ ] "when the default attributes are overridden" context (if applicable)
  - [ ] "when the required attributes are missing" context
  - [ ] Additional validation contexts (if applicable)
- [ ] `#to_h` with proper hash expectations (snake_case keys, symbols)
- [ ] `#to_json` with both camelCase and snake_case contexts
- [ ] `.from_json` with:
  - [ ] JSON string with camelCase keys
  - [ ] "initializes a[n] [type]" test
  - [ ] "parses [attribute]" test for EACH attribute
- [ ] Proper use of factories (`attributes_for`, `build`)
- [ ] URI fields wrapped in `URI()` where applicable
- [ ] Nested objects properly initialized in expectations
- [ ] Inline comments explaining factory usage
- [ ] `:aggregate_failures` metadata where appropriate