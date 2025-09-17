# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Essential Commands
```bash
# Setup development environment
bin/setup

# Interactive console for experimentation
bin/console

# Install gem locally for testing
bundle exec rake install

# Run all tests
bundle exec rspec

# Run tests with coverage (opens HTML report)
rake coverage

# Lint code with RuboCop
bundle exec rubocop

# Auto-fix RuboCop offenses (safe only)
bundle exec rubocop --autocorrect

# Run comprehensive quality assurance
rake qa
```

### Testing and Quality
```bash
# Run specific test file
bundle exec rspec spec/a2a_spec.rb

# Run tests with focus on failed specs
bundle exec rspec --only-failures

# Generate YARD documentation
bundle exec yard

# Type checking with Steep
bundle exec steep check

# Security audit
bundle exec bundle-audit

# Documentation coverage measurement
rake yardstick_measure
rake verify_measurements
```

### Development Workflow
```bash
# Watch files for changes (requires Guard)
bundle exec guard

# Build gem package
bundle exec rake build

# Release new version (updates version, creates tag, pushes to RubyGems)
bundle exec rake release
```

## Architecture Overview

### Core Structure
- **A2A Protocol Implementation**: Ruby implementation of the Agent2Agent communication protocol
- **Dry-Struct Based**: Uses `dry-struct` for typed data structures with validation
- **Case Transformation**: Automatic conversion between snake_case (Ruby) and camelCase (JSON protocol)
- **JSON-RPC Messages**: Full support for JSON-RPC request/response patterns

### Key Components

#### Extensions (`lib/a2a/extensions/`)
- **CaseTransformation**: Handles snake_case ↔ camelCase conversion during serialization
- **JSONDeserialization**: Enables creating objects directly from JSON strings
- **AdditionalProperties**: Supports flexible schema with extra properties

#### Types System (`lib/a2a/types/`)
- Protocol-compliant data structures (requests, responses, agents, tasks, etc.)
- All types inherit from `Dry::Struct` with validation
- Support for additional properties beyond defined attributes

### Development Environment
- **Ruby Version**: 3.4+ required
- **Type System**: RBS type definitions in `sig/` directory
- **Testing**: RSpec with FactoryBot for test data
- **Code Quality**: RuboCop with multiple plugins (performance, RSpec, factory_bot)
- **Documentation**: YARD with 100% coverage requirement
- **Security**: Bundler Audit integration
- **CI/CD**: Overcommit hooks for pre-commit validation

### Protocol Implementation Details
The gem provides Ruby objects for all A2A protocol message types:
- Task management (send, cancel, status)
- Agent capabilities and authentication
- File and artifact handling
- Push notifications
- Error handling with standardized codes

All objects support:
- Instantiation from hash data (with automatic key transformation)
- JSON serialization with protocol-compliant camelCase keys
- Type validation and additional property support
- Parsing from JSON strings via `from_json` methods