# A2A Ruby Gem - Product Requirements Document

## Overview

The `a2a` Ruby gem will implement Google's Agent-to-Agent (A2A) protocol, allowing Ruby developers to create A2A-compatible agents that can participate in the emerging ecosystem of interoperable AI agents. This PRD focuses on the server implementation that will allow developers to expose their agent capabilities through a standardized API.

## Target Users

- Ruby developers building AI agents or products
- Companies wanting to expose their services as A2A agents
- Developers integrating with other A2A-compatible services

## Scope

This PRD covers the implementation of:

1. Server-side components for creating an A2A-compatible agent
2. The API transport layer handling A2A protocol requests and responses
3. Task management for handling agent work
4. Support for streaming responses and push notifications
5. Integration with Ruby web frameworks via Rack

## Technical Requirements

### Core Interfaces

#### Agent Definition

The `A2A::Agent` class will be the central interface for developers to define their agent:

```ruby
agent = A2A::Agent.build do
  # Agent configuration
end
```

The builder DSL will support:

- Agent card definition
- Event hooks for task lifecycle
- Task handlers
- Streaming support configuration

#### Transport Layer

The `A2A::Transport` class will create a Rack-compatible application that handles HTTP requests according to the A2A protocol:

```ruby
app = A2A::Transport.new(agent)
run app
```

### Data Structure Classes

The following classes will be used to represent A2A protocol data structures (already implemented using dry-struct):

- `A2A::AgentCard`
- `A2A::AgentProvider`
- `A2A::AgentCapabilities`
- `A2A::AgentSkill`
- `A2A::Task`
- `A2A::TaskStatus`
- `A2A::Message`
- `A2A::Part`
- `A2A::Artifact`
- `A2A::PushNotificationConfig`

### Detailed Components

#### 1. Agent Builder DSL

```ruby
A2A::Agent.build do
  # Define agent card
  card do
    name 'Agent Name'
    description 'Agent Description'
    url 'https://agent-url.example.com'
    version '1.0.0'

    provider do
      organization 'My Organization'
      url 'https://organization.example.com'
    end

    capabilities do
      streaming true|false
      push_notifications true|false
      state_transition_history true|false
    end

    default_input_modes ['text/plain']
    default_output_modes ['text/plain']

    # Define skills
    skill 'Skill Name' do
      id 'skill-id'
      description 'Skill Description'
      tags ['tag1', 'tag2']
      examples ['example prompt 1', 'example prompt 2']
      input_modes ['text/plain'] # Optional, defaults to card's default_input_modes
      output_modes ['text/plain'] # Optional, defaults to card's default_output_modes
    end
  end

  # Define hooks
  before_task do |task|
    # Code to run before task processing begins
  end

  on_task_transition do |task, previous_state, current_state|
    # Code to run when task state changes
  end

  after_task do |task|
    # Code to run after task is completed
  end

  # Define task handlers
  on_task do |task|
    # Synchronous task handler
    # Must return a result or update task state
  end

  on_task_subscribe do |task, stream|
    # Streaming task handler
    # Can send incremental updates via stream
  end
end
```

#### 2. Task Processing Pipeline

The task processing pipeline should include:

1. **Task validation**: Ensure tasks have required fields and correct format
2. **Task state management**: Track and update task state through its lifecycle
3. **Task execution**: Run user-provided handlers for task processing
4. **Result generation**: Create and return properly formatted responses
5. **Event emission**: Trigger appropriate hooks at each stage

#### 3. Transport Layer (HTTP Implementation)

The transport layer must handle these A2A protocol endpoints:

1. `GET /.well-known/agent.json` - Return the agent card
2. `POST /jsonrpc` - Handle JSON-RPC 2.0 requests with these methods:
  - `tasks/send` - Process a new task or update an existing one
  - `tasks/sendSubscribe` - Process a task with streaming support
  - `tasks/get` - Retrieve task details
  - `tasks/cancel` - Cancel a task
  - `tasks/resubscribe` - Reconnect to stream updates for a task
  - `tasks/pushNotification/set` - Configure push notifications
  - `tasks/pushNotification/get` - Get push notification configuration

#### 4. Task Management

Implement a `TaskManager` class to:

1. Store and retrieve tasks (in-memory by default)
2. Maintain task history
3. Handle task state transitions
4. Support concurrent task processing
5. Manage task timeouts and expiration

#### 5. Streaming Support

For streaming tasks:

1. Implement SSE (Server-Sent Events) support
2. Enable incremental response updates
3. Handle client disconnections and reconnections
4. Support progress updates during long-running tasks

#### 6. Push Notification Support

For push notifications:

1. Support configuring external notification endpoints
2. Implement secure notification delivery
3. Handle notification failures
4. Provide retry mechanisms

## Implementation Details

### Task Flow

```
1. Client submits task via Transport layer
2. Transport layer validates request format
3. TaskManager creates or updates task
4. before_task hook is called
5. Task enters 'submitted' state
6. Agent processes task via on_task handler
7. Task state transitions occur (with on_task_transition hooks)
8. Results are accumulated
9. Task enters 'completed' state (or other terminal state)
10. after_task hook is called
11. Response is returned to client
```

### Streaming Task Flow

```
1. Client submits task with streaming via Transport layer
2. Transport layer validates request format
3. TaskManager creates or updates task
4. before_task hook is called
5. Task enters 'submitted' state
6. Transport layer establishes SSE connection
7. Agent processes task via on_task_subscribe handler
8. Handler sends incremental updates through provided stream object
9. Task state transitions occur (with on_task_transition hooks)
10. Task enters 'completed' state (or other terminal state)
11. after_task hook is called
12. SSE connection is closed
```

### Directory Structure

```
lib/
  a2a/
    version.rb
    agent.rb              # Main agent class & builder
    transport.rb          # Rack application & HTTP handling
    task_manager.rb       # Task storage and management
    streaming.rb          # Streaming support
    push_notification.rb  # Push notification support
    errors.rb             # Error classes
    types/                # Data structure classes (using dry-struct)
      agent_card.rb
      agent_provider.rb
      agent_capabilities.rb
      agent_skill.rb
      task.rb
      task_status.rb
      message.rb
      part.rb
      artifact.rb
      push_notification_config.rb
```

## Core Class Definitions

### A2A::Agent

```ruby
module A2A
  class Agent
    attr_reader :card, :task_manager, :hooks, :handlers

    def self.build(&block)
      new.tap { |agent| agent.instance_eval(&block) }
    end

    def initialize
      @hooks = {
        before_task: [],
        on_task_transition: [],
        after_task: []
      }
      @handlers = {
        on_task: nil,
        on_task_subscribe: nil
      }
      @task_manager = TaskManager.new
    end

    def card(&block)
      @card = CardBuilder.new.tap { |builder| builder.instance_eval(&block) }.build
    end

    def before_task(&block)
      @hooks[:before_task] << block
    end

    def on_task_transition(&block)
      @hooks[:on_task_transition] << block
    end

    def after_task(&block)
      @hooks[:after_task] << block
    end

    def on_task(&block)
      @handlers[:on_task] = block
    end

    def on_task_subscribe(&block)
      @handlers[:on_task_subscribe] = block
    end

    def process_task(task)
      # Implementation for processing a task
    end

    def process_streaming_task(task, stream)
      # Implementation for processing a streaming task
    end
  end
end
```

### A2A::Transport

```ruby
module A2A
  class Transport
    def initialize(agent)
      @agent = agent
    end

    def call(env)
      request = Rack::Request.new(env)

      case [request.request_method, request.path]
      when ['GET', '/.well-known/agent.json']
        handle_agent_card_request
      when ['POST', '/jsonrpc']
        handle_jsonrpc_request(request)
      else
        [404, {'Content-Type' => 'application/json'}, ['{"error":"Not Found"}']]
      end
    end

    private

    def handle_agent_card_request
      [200, {'Content-Type' => 'application/json'}, [@agent.card.to_json]]
    end

    def handle_jsonrpc_request(request)
      # Process JSON-RPC request and route to appropriate handler
    end

    def handle_tasks_send(params, id)
      # Handle tasks/send method
    end

    def handle_tasks_send_subscribe(params, id)
      # Handle tasks/sendSubscribe method with SSE
    end

    # Other method handlers...
  end
end
```

### A2A::TaskManager

```ruby
module A2A
  class TaskManager
    def initialize
      @tasks = {}
      @mutex = Mutex.new
    end

    def create_task(id, session_id, message)
      # Create and store a new task
    end

    def get_task(id)
      # Retrieve a task by ID
    end

    def update_task(id, updates)
      # Update a task with new data
    end

    def transition_task(id, new_state, message = nil)
      # Change task state with proper hooks
    end

    def cancel_task(id)
      # Cancel a task
    end

    # Other task management methods...
  end
end
```

## Integration with OpenAI/LLMs

The gem should provide easy integration with LLMs via the ruby-openai gem:

```ruby
A2A::Agent.build do
  # Other configuration...

  on_task do |task|
    # Extract text from task
    text = task.message.parts.first.text

    # Use OpenAI to generate a response
    openai_client = OpenAI::Client.new
    response = openai_client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [{ role: "user", content: text }]
      }
    )

    # Update task with the response
    response_text = response.dig("choices", 0, "message", "content")
    task.add_artifact(
      parts: [{ type: "text", text: response_text }]
    )

    # Transition task to completed state
    task.complete
  end
end
```

## Streaming with OpenAI Example

```ruby
A2A::Agent.build do
  # Other configuration...

  capabilities do
    streaming true
    # Other capabilities...
  end

  on_task_subscribe do |task, stream|
    # Extract text from task
    text = task.message.parts.first.text

    # Use OpenAI with streaming
    openai_client = OpenAI::Client.new
    openai_client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [{ role: "user", content: text }],
        stream: proc do |chunk, _bytesize|
          content = chunk.dig("choices", 0, "delta", "content")
          if content
            # Send incremental update to client
            stream.write({
              id: task.id,
              artifact: {
                parts: [{ type: "text", text: content }],
                index: 0,
                append: true,
                lastChunk: false
              }
            })
          end
        end
      }
    )

    # Mark the task as complete
    stream.write({
      id: task.id,
      status: {
        state: "completed",
        timestamp: Time.now.iso8601
      },
      final: true
    })
  end
end
```

## Configuration Options

The gem should support configuration options:

```ruby
A2A.configure do |config|
  config.default_task_timeout = 60 # seconds
  config.max_tasks = 1000 # maximum number of tasks to store in memory
  config.task_cleanup_interval = 3600 # seconds between cleanup runs
  config.logger = Rails.logger # custom logger
  config.authentication_handler = ->(request) { ... } # custom auth
end
```

## Advanced Features

### Task Persistence

Optional persistence backends for tasks:

```ruby
A2A::Agent.build do
  # Use Redis for task storage
  task_store A2A::TaskStore::Redis.new(url: 'redis://localhost:6379/0')

  # Or custom store
  task_store MyCustomTaskStore.new
end
```

### Authentication

Support for standard auth methods:

```ruby
A2A::Agent.build do
  card do
    # Other card configuration...

    authentication do
      schemes ['bearer']
    end
  end

  authenticate do |request|
    # Validate auth token and return true/false
    token = request.env['HTTP_AUTHORIZATION']&.slice(7..-1) # Remove 'Bearer '
    MyAuthService.validate_token(token)
  end
end
```

### Error Handling

```ruby
A2A::Agent.build do
  # Other configuration...

  on_error do |error, context|
    # Log error and possibly notify monitoring systems
    Sentry.capture_exception(error, extra: { task_id: context[:task_id] })
  end
end
```

## Development Roadmap

### MVP (v0.1.0)

- Basic Agent builder DSL
- In-memory task management
- Support for A2A protocol endpoints
- Task lifecycle hooks
- Simple synchronous task handling

### Phase 2 (v0.2.0)

- Streaming support via SSE
- Task state transition history
- Better error handling
- Enhanced validation

### Phase 3 (v0.3.0)

- Push notification support
- Task persistence options
- Authentication support
- Performance optimizations

### Future Enhancements

- Tool support (similar to function calling in OpenAI)
- Advanced monitoring and metrics
- CLI for agent development
- Support for additional LLM providers
- Multi-agent coordination

## Testing Strategy

The gem should include:

1. Unit tests for each component
2. Integration tests for full A2A protocol compliance
3. Performance tests for concurrency and streaming
4. Example agents for different use cases

## Documentation

Documentation should include:

1. Getting Started guide
2. Full DSL reference
3. A2A protocol overview
4. Examples for common use cases:
  - Simple echo agent
  - LLM-powered agent
  - Tool-using agent
  - File processing agent
  - Multi-agent collaboration

## Example Usage

Here's a complete example of a simple echo agent:

```ruby
require 'a2a'
require 'rack'

agent = A2A::Agent.build do
  card do
    name 'Echo Agent'
    description 'A simple agent that echoes back your messages'
    url 'http://localhost:9292'
    version '1.0.0'

    capabilities do
      streaming true
      push_notifications false
      state_transition_history false
    end

    default_input_modes ['text/plain']
    default_output_modes ['text/plain']

    skill 'Echo' do
      id 'echo'
      description 'Echoes back your message'
      tags ['utility', 'echo']
      examples ['Hello, world!']
    end
  end

  on_task do |task|
    # Extract text from the message
    text = task.message.parts.find { |part| part.type == 'text' }&.text || 'No text found'

    # Create response artifact
    task.add_artifact(
      name: 'echo-response',
      parts: [{ type: 'text', text: "Echo: #{text}" }]
    )

    # Mark task as completed
    task.complete
  end

  on_task_subscribe do |task, stream|
    # Extract text from the message
    text = task.message.parts.find { |part| part.type == 'text' }&.text || 'No text found'
    response_text = "Echo: #{text}"

    # Send response character by character with small delays
    task.transition_to('working')

    response_text.each_char do |char|
      stream.write({
        id: task.id,
        artifact: {
          parts: [{ type: 'text', text: char }],
          index: 0,
          append: true,
          lastChunk: false
        }
      })
      sleep 0.1 # Simulate slow processing
    end

    # Mark as complete
    stream.write({
      id: task.id,
      status: {
        state: 'completed',
        timestamp: Time.now.iso8601
      },
      final: true
    })
  end
end

# Create and run the Rack application
app = A2A::Transport.new(agent)
Rack::Handler::WEBrick.run app, Port: 9292
```

## Conclusion

This implementation of the A2A protocol as a Ruby gem will enable Ruby developers to create interoperable AI agents that can participate in the emerging A2A ecosystem. The gem's design emphasizes simplicity, flexibility, and adherence to the A2A protocol specification while maintaining Ruby's idiomatic style.

By following this PRD, the gem will provide a solid foundation for building A2A-compatible agents in Ruby, with a clear path for extending functionality as the protocol evolves.
