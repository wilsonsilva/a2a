# frozen_string_literal: true

require 'json'

module A2A
  # Streaming module for handling Server-Sent Events (SSE)
  module Streaming
    # SSEWriter class that handles writing SSE events to a stream
    class SSEWriter
      # Initialize a new SSEWriter
      # @param io [#write] The IO object to write to
      def initialize(io)
        @io = io
      end

      # Write an SSE event
      # @param event [String] The event name
      # @param data [Hash, String] The event data
      # @param id [String, nil] Optional event ID
      # @param retry_ms [Integer, nil] Optional retry timeout in milliseconds
      # @return [self] Returns self for method chaining
      def write(event, data, id: nil, retry_ms: nil)
        # Write event field if provided
        @io.write("event: #{event}\n") if event

        # Write id field if provided
        @io.write("id: #{id}\n") if id

        # Write retry field if provided
        @io.write("retry: #{retry_ms}\n") if retry_ms

        # Format data as JSON if it's not a string
        data_str = data.is_a?(String) ? data : data.to_json

        # Write data field, handling multi-line data
        data_str.each_line do |line|
          @io.write("data: #{line.chomp}\n")
        end

        # Terminate the event with an empty line
        @io.write("\n")
        @io.flush

        self
      end

      # Write a ping event (comment) to keep the connection alive
      # @return [self] Returns self for method chaining
      def ping
        @io.write(": ping\n\n")
        @io.flush
        self
      end

      # Close the SSE stream
      def close
        @io.close if @io.respond_to?(:close)
      end
    end

    # SSEResponse class for creating Rack-compatible SSE responses
    class SSEResponse
      include Enumerable

      # Initialize a new SSEResponse
      # @param block [Proc] Block to execute with the SSEWriter
      def initialize(&block)
        @block = block
      end

      # Return SSE headers
      # @return [Hash] The HTTP headers for an SSE response
      def headers
        {
          'Content-Type' => 'text/event-stream',
          'Cache-Control' => 'no-cache',
          'Connection' => 'keep-alive'
        }
      end

      # Make the response Rack-compatible by implementing each
      # @yield [String] Yields each chunk of the SSE stream
      def each
        # Create an SSE writer that writes to a StringIO
        # and yields each chunk to the Rack server
        io = Object.new
        def io.write(data)
          @last_data = data
          data.length
        end

        def io.flush
          yield @last_data if @last_data
          @last_data = nil
        end

        def io.close
          # Nothing to do
        end

        # Allow yielding from the flush method
        io.define_singleton_method(:flush) do
          yield @last_data if @last_data
          @last_data = nil
        end

        writer = SSEWriter.new(io)

        # Execute the block with the writer
        @block.call(writer)
      ensure
        writer&.close
      end
    end

    # Create a streaming task response
    # @param task_id [String] The task ID
    # @param processor [TaskProcessor] The task processor
    # @param task_manager [TaskManager] The task manager
    # @return [SSEResponse] A Rack-compatible SSE response
    def self.stream_task(task_id, processor, task_manager)
      SSEResponse.new do |sse|
        begin
          # Get the task
          task = task_manager.get_task(task_id)

          # Send initial task event
          sse.write('taskId', { task_id: task_id })

          # Set up callbacks for streaming updates
          callbacks = {
            on_status_update: ->(updated_task, status) {
              event = TaskStatusUpdateEvent.new(
                task_id: task_id,
                status: status
              )
              sse.write('taskStatusUpdate', event)
            },
            on_artifact_update: ->(updated_task, artifact) {
              event = Types::TaskArtifactUpdateEvent.new(
                task_id: task_id,
                artifact: artifact
              )
              sse.write('taskArtifactUpdate', event)
            }
          }

          # Process the task with callbacks
          processor.process(task, callbacks)

          # Send a final ping to ensure all data is flushed
          sse.ping

        rescue StandardError => e
          # Send error as a status update
          error_status = TaskStatus.new(
            state: 'failed',
            message: Message.new(
              parts: [TextPart.new(text: "Error: #{e.message}")],
              role: 'agent'
            )
          )
          error_event = TaskStatusUpdateEvent.new(
            task_id: task_id,
            status: error_status
          )

          sse.write('taskStatusUpdate', error_event)
        end
      end
    end
  end
end
