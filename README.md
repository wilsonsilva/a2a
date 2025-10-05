# Agent2Agent (A2A) protocol

[![Gem Version](https://badge.fury.io/rb/a2a.svg)](https://badge.fury.io/rb/a2a)
![Build](https://github.com/wilsonsilva/a2a/actions/workflows/main.yml/badge.svg)
[![Maintainability](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/maintainability.svg)](https://qlty.sh/gh/wilsonsilva/projects/a2a)
[![Code Coverage](https://qlty.sh/badges/73ebc4bb-d1db-4b5b-9a7c-a4acd59dfe69/test_coverage.svg)](https://qlty.sh/gh/wilsonsilva/projects/a2a)

An open protocol enabling communication and interoperability between opaque agentic applications.

## Table of contents

- [Key features](#-key-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Documentation](#-documentation)
- [Development](#-development)
  * [Type checking](#type-checking)
- [Contributing](#-contributing)
- [License](#-license)
- [Code of Conduct](#-code-of-conduct)

## 🔑 Key features

- Protocol data structures defined according to the Agent2Agent specification
- Serialization and deserialization of protocol messages
- Typed data structures with validation
- Case transformation support (snake_case ↔ camelCase) during instantiation and serialization
- Flexible schema with support for additional properties beyond defined attributes

## 📦 Installation

Install the gem by executing:

    $ gem install a2a

## ⚡️ Quickstart

```ruby
require 'a2a'

# Create message parts
text_part = A2A::TextPart.new(text: 'Plan a trip to Paris')

# Create a message
message = A2A::Message.new(
  role: 'user',
  parts: [text_part],
  message_id: 'msg-123',
  kind: 'message'
)

# Create message send parameters object
message_params = A2A::MessageSendParams.new(
  message: message
)

# Build a JSON-RPC request object (no actual network request is made)
request = A2A::SendMessageRequest.new(
  id: 1,
  params: message_params
)

# Convert to JSON with camelCase formatting (as per protocol spec)
json_request = request.to_json
puts json_request
# => {"jsonrpc":"2.0","id":1,"method":"message/send","params":{"message":{"role":"user","parts":[{"kind":"text","text":"Plan a trip to Paris"}],"messageId":"msg-123","kind":"message"}}}

# Parse a JSON response string
agent_response = '{"jsonrpc":"2.0","id":1,"result":{"id":"task-123","contextId":"ctx-456","status":{"state":"completed"},"kind":"task"}}'

# Method 1: Parse the JSON first, then create the object
response_data = JSON.parse(agent_response)
response = A2A::SendMessageResponse.new(response_data)

# Method 2: Directly create the object from JSON (using the new from_json method)
response = A2A::SendMessageResponse.from_json(agent_response)

# Access the task information
if response.result
  puts "Task status: #{response.result.status}"
  puts "Messages: #{response.result.history&.length || 0}"
else
  puts "Error: #{response.error&.message}"
end
```

## 📚 Documentation

- [YARD documentation](https://rubydoc.info/gems/a2a)

## 🔨 Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

The health and maintainability of the codebase is ensured through a set of
Rake tasks to test, lint and audit the gem for security vulnerabilities and documentation:

```
rake build                    # Build a2a.gem into the pkg directory
rake build:checksum           # Generate SHA512 checksum if a2a.gem into the checksums directory
rake bundle:audit:check       # Checks the Gemfile.lock for insecure dependencies
rake bundle:audit:update      # Updates the bundler-audit vulnerability database
rake clean                    # Remove any temporary products
rake clobber                  # Remove any generated files
rake coverage                 # Run spec with coverage
rake install                  # Build and install a2a.gem into system gems
rake install:local            # Build and install a2a.gem into system gems without network access
rake qa                       # Test, lint and perform security and documentation audits
rake release[remote]          # Create a tag, build and push a2a.gem to rubygems.org
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
rake spec                     # Run RSpec code examples
rake verify_measurements      # Verify that yardstick coverage is at least 100%
rake yard                     # Generate YARD Documentation
rake yard:junk                # Check the junk in your YARD Documentation
rake yardstick_measure        # Measure docs in lib/**/*.rb with yardstick
```

### Type checking

This gem leverages [RBS](https://github.com/ruby/rbs), a language to describe the structure of Ruby programs. It is
used to provide type checking and autocompletion in your editor. Run `bundle exec typeprof FILENAME` to generate
an RBS definition for the given Ruby file. And validate all definitions using [Steep](https://github.com/soutaro/steep)
with the command `bundle exec steep check`.

## 🐞 Issues & Bugs

If you find any issues or bugs, please report them [here](https://github.com/wilsonsilva/a2a/issues), I will be happy
to have a look at them and fix them as soon as possible.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilsonsilva/a2a.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](https://github.com/wilsonsilva/a2a/blob/main/CODE_OF_CONDUCT.md).

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👔 Code of Conduct

Everyone interacting in the A2A Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/wilsonsilva/a2a/blob/main/CODE_OF_CONDUCT.md).
