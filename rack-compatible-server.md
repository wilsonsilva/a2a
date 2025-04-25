# A2A Ruby Gem - Server Implementation PRD

## Overview

This Product Requirements Document (PRD) outlines the requirements and specifications for implementing the Agent2Agent (A2A) protocol server in a Ruby gem. The gem, named 'a2a', will provide an idiomatic Ruby interface for creating and managing A2A servers that can communicate with clients according to the A2A specification.

The A2A protocol enables interoperability between AI agents across diverse frameworks and vendors by standardizing their communication. This implementation will allow Ruby developers to create A2A-compliant servers that can participate in this ecosystem.

## Current State

- The gem scaffold has been created with zeitwerk for autoloading
- Data structures from the JSON schema have been implemented using dry-struct
- Classes use snake_case in Ruby and handle serialization/deserialization to/from camelCase

## Goals

- Create an idiomatic Ruby implementation of the A2A server specification
- Provide a simple DSL for defining agents, skills, and handling tasks
- Ensure compatibility with the Rack specification for broad framework compatibility
- Make the server implementation thread-safe and performant
- Support all required A2A endpoints and features
- Implement proper error handling according to the A2A specification
- Support streaming responses via Server-Sent Events (SSE)
- Allow extensibility for future protocol updates

## Non-Goals

- Implementing client-side functionality (will be covered in a separate phase)
- Creating example agents or skills (will be provided as separate gems or examples)
- Authentication implementation (will provide hooks for developers to plug in their auth system)

## Technical Requirements

### 1. Server Architecture

#### 1.1 Rack Compatibility

The server must be compatible with the Rack specification to ensure it can be used with various Ruby web frameworks:

```ruby
# Example usage with Rack
require 'a2a'

agent = A2A::Agent.build do
  name "Echo Agent"
  description "This agent echoes the input given"
  url "http://localhost:9292/"
  version "0.1.0"

  capabilities do
    streaming true
    push_notifications false
    state_transition_history false
  end

  default_input_modes ["text/plain"]
  default_output_modes ["text/plain"]

  skill "echo" do
    name "Echo Tool"
    description "Echoes the input given"
    tags ["echo", "repeater"]
    examples ["I will see this echoed back to me"]
  end

  # Task handlers
  on_task do |task|
    # Handle incoming tasks
    text = task.message.parts.first.text
    task.complete("You said: #{text}")
  end

  on_task_subscribe do |task, stream|
    # Handle streaming task
    text = task.message.parts.first.text
    stream.send_update("Processing: #{text}", state: "working")
    sleep 1
    stream.send_update("Finished processing!", state: "completed", final: true)
  end
end

# Create a Rack application
app = A2A::RackApp.new(agent)

# Run with any Rack handler
run app
```

#### 1.2 Framework Integration

For popular frameworks, provide specific integration modules:

```ruby
# Rails integration
# config/routes.rb
Rails.application.routes.draw do
  mount A2A::Rails::App.new(MyAgent) => "/a2a"
end

# Sinatra integration
class MyApp < Sinatra::Base
  register A2A::Sinatra

  a2a_agent do
    name "My Sinatra Agent"
    # ...
  end
end

# Roda integration
class MyApp < Roda
  plugin :a2a

  a2a_agent do
    name "My Roda Agent"
    # ...
  end

  route do |r|
    r.a2a
  end
end
```

### 2. Server Core Components

#### 2.1 Agent Definition

The server must provide a DSL for defining agent cards and skills:

```ruby
A2A::Agent.build do
  name "My Agent"
  description "A useful agent for demonstration"
  url "https://my-agent.example.com"
  version "1.0.0"

  provider do
    organization "Example, Inc."
    url "https://example.com"
  end

  documentation_url "https://docs.example.com/my-agent"

  capabilities do
    streaming true
    push_notifications true
    state_transition_history true
  end

  authentication do
    schemes ["bearer"]
  end

  default_input_modes ["text/plain", "application/json"]
  default_output_modes ["text/plain", "application/json"]

  skill "analysis" do
    id "data-analysis"  # optional, defaults to name as snake_case
    description "Analyzes data and provides insights"
    tags ["data", "analysis", "insights"]
    examples [
      "Analyze this CSV file",
      "Find patterns in this dataset"
    ]
    # Override the modes for this specific skill
    input_modes ["text/plain", "text/csv", "application/json"]
    output_modes ["text/plain", "application/json", "image/png"]
  end

  # Additional skills...
  skill "summarize" do
    # ...
  end
end
```

#### 2.2 Task Management

Implement a task management system that handles:

```ruby
# Task handling with a block
on_task do |task|
  # process the task
  user_message = task.message.parts.first.text

  # Create an artifact response
  task.complete("Here's my response to: #{user_message}")
end

# Alternatively, register a class as a handler
on_task TaskHandler.new

# For streaming responses
on_task_subscribe do |task, stream|
  # Send stream updates
  stream.send_status_update("working", "Processing your request...")

  # Do some work
  result = process_task(task)

  # Send artifact updates
  stream.send_artifact_update(result, append: false, last_chunk: false)

  # More processing
  additional_result = process_more(task)

  # Send more artifact data
  stream.send_artifact_update(additional_result, append: true, last_chunk: true)

  # Complete the task
  stream.send_status_update("completed", "Task is finished", final: true)
end
```

#### 2.3 API Endpoints

Implement all required A2A API endpoints:

1. `GET /.well-known/agent.json` - Return the agent card
2. `POST /` - Handle JSON-RPC requests for:
  - `tasks/send` - Create or update a task
  - `tasks/get` - Get task information
  - `tasks/cancel` - Cancel a task
  - `tasks/sendSubscribe` - Create or update a task with streaming response
  - `tasks/resubscribe` - Resubscribe to streaming updates for a task
  - `tasks/pushNotification/set` - Set push notification configuration
  - `tasks/pushNotification/get` - Get push notification configuration

### 3. Task Storage and State Management

#### 3.1 Task Storage Interface

```ruby
module A2A
  module Storage
    class Base
      def initialize(options = {})
        # Initialize storage with options
      end

      def create_task(id, session_id, message, metadata = {})
        # Create a new task
        raise NotImplementedError
      end

      def update_task(id, updates)
        # Update an existing task
        raise NotImplementedError
      end

      def get_task(id)
        # Retrieve a task
        raise NotImplementedError
      end

      def list_tasks(filters = {})
        # List tasks with optional filters
        raise NotImplementedError
      end

      def delete_task(id)
        # Delete a task
        raise NotImplementedError
      end
    end

    # Built-in storage options
    class InMemory < Base
      # Implement methods with in-memory data structures
    end

    class Redis < Base
      # Implement methods with Redis
    end
  end
end
```

#### 3.2 Task State Management

```ruby
class A2A::Task
  # Methods for state transitions
  def working(message = nil)
    update_status("working", message)
  end

  def require_input(message)
    update_status("input-required", message)
  end

  def complete(message = nil, artifacts = nil)
    if artifacts
      add_artifacts(artifacts)
    elsif message
      add_artifact_from_message(message)
    end
    update_status("completed", message)
  end

  def cancel(message = nil)
    update_status("canceled", message)
  end

  def fail(message)
    update_status("failed", message)
  end

  # Artifact management
  def add_artifact(artifact)
    # Add a single artifact
  end

  def add_artifacts(artifacts)
    # Add multiple artifacts
  end

  def add_artifact_from_message(message)
    # Convenience method to create an artifact from a message
  end
end
```

### 4. Streaming Support

#### 4.1 Server-Sent Events (SSE) Implementation

```ruby
module A2A
  class StreamManager
    def initialize(task)
      @task = task
      @subscribers = []
    end

    def add_subscriber(subscriber)
      @subscribers << subscriber
    end

    def remove_subscriber(subscriber)
      @subscribers.delete(subscriber)
    end

    def send_status_update(state, message = nil, final: false)
      update = build_status_update(state, message, final)
      broadcast(update)
    end

    def send_artifact_update(content, append: false, last_chunk: false)
      update = build_artifact_update(content, append, last_chunk)
      broadcast(update)
    end

    private

    def broadcast(update)
      @subscribers.each do |subscriber|
        subscriber.send_event(update)
      end
    end

    def build_status_update(state, message, final)
      # Build status update object
    end

    def build_artifact_update(content, append, last_chunk)
      # Build artifact update object
    end
  end

  class SSESubscriber
    def initialize(response)
      @response = response
    end

    def send_event(data)
      # Format data as an SSE event and send it to the response
      event_data = JSON.generate(data)
      @response.write("data: #{event_data}\n\n")
      @response.flush
    end
  end
end
```

#### 4.2 Integration with Web Servers

For different web servers, provide appropriate implementations:

```ruby
module A2A
  module SSE
    class Rack
      # Implement SSE for Rack
    end

    class Puma
      # Implement SSE for Puma
    end

    class Unicorn
      # Implement SSE for Unicorn
    end
  end
end
```

### 5. Error Handling

Implement proper error handling according to the A2A specification:

```ruby
module A2A
  module Errors
    class Base < StandardError
      attr_reader :code, :data

      def initialize(message, data = nil)
        super(message)
        @data = data
      end

      def to_json_rpc
        {
          code: code,
          message: message,
          data: data
        }
      end
    end

    class JSONParse < Base
      def code; -32700; end
    end

    class InvalidRequest < Base
      def code; -32600; end
    end

    class MethodNotFound < Base
      def code; -32601; end
    end

    class InvalidParams < Base
      def code; -32602; end
    end

    class Internal < Base
      def code; -32603; end
    end

    class TaskNotFound < Base
      def code; -32001; end
    end

    class TaskCannotBeCanceled < Base
      def code; -32002; end
    end

    class PushNotificationsNotSupported < Base
      def code; -32003; end
    end

    class UnsupportedOperation < Base
      def code; -32004; end
    end

    class IncompatibleContentTypes < Base
      def code; -32005; end
    end
  end

  class ErrorHandler
    def self.handle(request, error)
      # Map Ruby exceptions to A2A error responses
      response = {
        jsonrpc: "2.0",
        id: request.id
      }

      case error
      when Errors::Base
        response[:error] = error.to_json_rpc
      when JSON::ParserError
        response[:error] = Errors::JSONParse.new("Invalid JSON payload").to_json_rpc
      else
        response[:error] = Errors::Internal.new("Internal error").to_json_rpc
      end

      response
    end
  end
end
```

### 6. Push Notification Support

Implement support for push notifications:

```ruby
module A2A
  class PushNotificationManager
    def initialize(agent)
      @agent = agent
    end

    def register(task_id, config)
      # Register push notification configuration for a task
    end

    def unregister(task_id)
      # Unregister push notifications for a task
    end

    def get_config(task_id)
      # Get push notification configuration for a task
    end

    def send_notification(task_id, payload)
      config = get_config(task_id)
      return unless config

      # Send push notification to the configured URL
      client = HTTP.headers("Content-Type" => "application/json")

      # Add authentication if specified
      if config.authentication
        case config.authentication.schemes.first
        when "bearer"
          client = client.auth("Bearer #{config.token}")
        when "jwt"
          # Generate JWT
          client = client.headers("Authorization" => "Bearer #{generate_jwt(task_id, config)}")
        end
      end

      # Send the notification
      client.post(config.url, json: payload)
    end

    private

    def generate_jwt(task_id, config)
      # Generate a JWT for authentication
    end
  end
end
```

### 7. Middleware and Extension Points

Provide middleware for customizing request processing:

```ruby
module A2A
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Process the request before passing it to the app
      @app.call(env)
      # Process the response
    end
  end

  class Server
    def use(middleware, *args, &block)
      # Add middleware to the server
      @middlewares << [middleware, args, block]
    end

    # Hooks for various events
    def before_task(&block)
      @before_task_hooks << block
    end

    def after_task(&block)
      @after_task_hooks << block
    end

    def before_send(&block)
      @before_send_hooks << block
    end

    def after_send(&block)
      @after_send_hooks << block
    end
  end
end
```

## Implementation Phases

### Phase 1: Core Server and DSL
- Implement the Agent Card DSL
- Create the basic server structure
- Implement the JSON-RPC request handler
- Set up the task management system

### Phase 2: Task Handling and Storage
- Implement task creation and retrieval
- Create the in-memory storage backend
- Add support for task state transitions
- Implement artifact creation and management

### Phase 3: Streaming and Push Notifications
- Implement Server-Sent Events (SSE) for streaming responses
- Add support for task subscriptions
- Implement push notification configuration and delivery
- Create hooks for authentication and security

### Phase 4: Framework Integration and Testing
- Create framework-specific adapters (Rails, Sinatra, Roda)
- Implement comprehensive testing
- Optimize performance
- Create documentation and examples

## Design Decisions and Considerations

### Idiomatic Ruby
- Use a DSL for configuration to make it feel natural to Ruby developers
- Follow Ruby naming conventions (snake_case) internally
- Provide both block-based and object-oriented interfaces

### Performance
- Ensure thread-safety for concurrent requests
- Use efficient data structures for in-memory storage
- Provide hooks for custom storage backends

### Extensibility
- Use a plugin system for optional features
- Provide clear extension points for customization
- Design with future protocol changes in mind

### Security
- Support various authentication schemes
- Implement proper validation of inputs
- Provide secure defaults

## Example Implementation

```ruby
# Complete agent definition example
require 'a2a'

agent = A2A::Agent.build do
  name "Content Assistant"
  description "AI assistant for content creation and editing"
  url "https://content-assistant.example.com"
  version "1.0.0"

  provider do
    organization "Example, Inc."
    url "https://example.com"
  end

  capabilities do
    streaming true
    push_notifications true
    state_transition_history true
  end

  authentication do
    schemes ["bearer"]
  end

  default_input_modes ["text/plain", "application/json"]
  default_output_modes ["text/plain", "application/json"]

  skill "write" do
    name "Content Writing"
    description "Write new content based on instructions"
    tags ["writing", "content"]
    examples [
      "Write a blog post about AI",
      "Create a product description for a new smartphone"
    ]
  end

  skill "edit" do
    name "Content Editing"
    description "Edit and improve existing content"
    tags ["editing", "proofreading"]
    examples [
      "Edit this article for clarity",
      "Proofread this document"
    ]
  end

  # Use middleware for authentication
  use A2A::Middleware::Authentication do |request, env|
    # Verify bearer token
    token = env['HTTP_AUTHORIZATION']&.gsub('Bearer ', '')

    # Use your authentication logic here
    if token == 'valid-token'
      true
    else
      raise A2A::Errors::InvalidRequest.new("Invalid authentication")
    end
  end

  # Hook for logging
  before_task do |task|
    # Log task details
    puts "Task received: #{task.id}"
  end

  # Task handlers
  on_task do |task|
    case task.skill_id
    when "write"
      write_content(task)
    when "edit"
      edit_content(task)
    else
      task.fail("Unsupported skill")
    end
  end

  on_task_subscribe do |task, stream|
    skill_id = task.skill_id

    stream.send_status_update("working", "Processing your request")

    # Stream chunks of content
    if skill_id == "write"
      stream_writing_process(task, stream)
    elsif skill_id == "edit"
      stream_editing_process(task, stream)
    else
      stream.send_status_update("failed", "Unsupported skill", final: true)
    end
  end

  # Define helper methods for use in handlers
  helper do
    def write_content(task)
      input = task.message.parts.first.text
      # Generate content based on input
      result = "Here's your new content based on: #{input}"
      task.complete(result)
    end

    def edit_content(task)
      input = task.message.parts.first.text
      # Edit the provided content
      result = "Here's your edited content: #{input.upcase}"
      task.complete(result)
    end

    def stream_writing_process(task, stream)
      input = task.message.parts.first.text

      # Stream parts of the content
      intro = "Introduction based on: #{input}"
      body = "Main content expanding on the topic."
      conclusion = "Conclusion summarizing key points."

      stream.send_artifact_update(intro, append: false, last_chunk: false)
      sleep 1 # Simulate processing time

      stream.send_artifact_update(body, append: true, last_chunk: false)
      sleep 1

      stream.send_artifact_update(conclusion, append: true, last_chunk: true)

      stream.send_status_update("completed", "Writing complete", final: true)
    end

    def stream_editing_process(task, stream)
      # Similar implementation for editing
    end
  end
end

# Create a Rack application
app = A2A::RackApp.new(agent)

# Run with Rack
use Rack::Logger
run app
```

## Development Guidelines

### Testing

- Write comprehensive unit tests for all components
- Create integration tests for the full server flow
- Test with different Rack handlers and web frameworks
- Implement performance tests for streaming and concurrency

### Documentation

- Create detailed API documentation
- Provide example implementations for common use cases
- Add inline documentation for all public methods
- Create a comprehensive README with quick start guide

### Versioning

- Follow semantic versioning
- Maintain backward compatibility when possible
- Clearly document breaking changes
- Provide migration guides for major version updates

## Future Enhancements

### Phase 5: Advanced Features
- Implement Redis or database storage backends
- Add support for complex artifact types
- Create advanced monitoring and metrics
- Implement rate limiting and throttling

### Phase 6: Client Implementation
- Create a client library for connecting to A2A servers
- Implement client-side streaming support
- Add support for push notification reception
- Create a unified client-server interface for agent-to-agent communication
