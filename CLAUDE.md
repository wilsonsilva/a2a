# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

This is the A2A (Agent2Agent) Ruby gem - an implementation of the Agent2Agent protocol enabling communication and
interoperability between opaque agentic applications. The gem provides typed data structures,
serialization/deserialization, and validation according to the A2A specification.

## Development Commands

### Testing and Quality Assurance
- `bundle exec rake spec` - Run RSpec tests
- `bundle exec rake coverage` - Run tests with coverage report (opens browser)
- `bundle exec rake qa` - Run full quality assurance suite (tests, linting, docs, security audit)
- `bundle exec rspec spec/path/to/specific_spec.rb` - Run a single test file
- `bundle exec rspec spec/path/to/specific_spec.rb:42` - Run specific test by line number

### Code Quality
- `bundle exec rake rubocop` - Run RuboCop linting
- `bundle exec rake rubocop:autocorrect` - Auto-fix safe RuboCop offenses
- `bundle exec rake rubocop:autocorrect_all` - Auto-fix all RuboCop offenses (including unsafe)

### Documentation
- `bundle exec rake yard` - Generate YARD documentation
- `bundle exec rake yard:junk` - Check for documentation issues
- `bundle exec rake verify_measurements` - Ensure 100% documentation coverage (yardstick)

### Type Checking (Optional but Available)
- `bundle exec typeprof lib/a2a.rb` - Generate RBS type signatures
- `bundle exec steep check` - Run Steep type checking

### Security
- `bundle exec rake bundle:audit:check` - Check for security vulnerabilities
- `bundle exec rake bundle:audit:update` - Update security vulnerability database

### Build and Release
- `bundle exec rake build` - Build gem
- `bundle exec rake install` - Install gem locally
- `bin/console` - Open interactive console with gem loaded

## Architecture Overview

### Core Structure
The gem is organized around the A2A protocol specification with the following key components:

1. **Type System (`lib/a2a/types/`)**: Complete typed implementation of A2A protocol data structures
   - Agent discovery objects (AgentCard, AgentSkill, AgentCapabilities)
   - Message and task objects (Message, Task, TaskStatus, Artifact)
   - Security schemes and authentication structures
   - JSON-RPC request/response objects
   - Implements the type system defined in `.agent-docs/types.ts` (TypeScript reference definitions)
   - Type mapping between TypeScript types/interfaces and Ruby classes documented in `.agent-docs/types_mapping.md`

2. **Extensions System (`lib/a2a/extensions/`)**:
   - `AdditionalProperties`: Allows flexible schema with additional properties beyond defined attributes
   - `JSONDeserialization`: Handles case transformation (snake_case ↔ camelCase) during instantiation

### Key Design Patterns

1. **Case Transformation**: The gem handles automatic conversion between Ruby's snake_case conventions and the protocol's camelCase requirements during serialization/deserialization.
2. **Typed Data Structures**: All protocol objects are implemented as Ruby classes with proper validation and type checking support via RBS signatures.
3. **JSON-RPC Integration**: Built on the `jsonrpc-middleware` gem for proper JSON-RPC 2.0 protocol compliance.
4. **Factory Pattern**: Test factories are provided for all major objects to support testing.

### File Organization
- `lib/a2a.rb` - Main entry point with Zeitwerk loader configuration
- `lib/a2a/types/` - All protocol data structure implementations (collapsed namespace)
- `lib/a2a/extensions/` - Mixin modules for additional functionality
- `spec/` - RSpec test suite with comprehensive coverage
- `sig/a2a.rbs` - RBS type signatures for type checking

## Development Guidelines

### Code Style
- Follow RuboCop configuration in `.rubocop.yml`
- Target Ruby 3.4 compatibility
- Use single quotes for strings, double quotes in interpolation
- Max line length: 120 characters
- Frozen string literals required

### Testing
- Use RSpec for all tests
- FactoryBot factories for test data
- Match JSON matchers for JSON comparison
- Aim for comprehensive test coverage
- Tests are organized to mirror the lib structure

### Quality Thresholds
- 100% documentation coverage enforced by yardstick
- RuboCop compliance required
- Security audit checks via bundler-audit
- Type checking available via Steep

### Git Workflow
- Overcommit hooks enforce RuboCop and trailing whitespace checks on pre-commit
- Follow conventional commit message format based on existing history
