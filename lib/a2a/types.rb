# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'
require 'json'
require 'time' # Required for ISO 8601 time formatting
require 'securerandom' # Required for default IDs
require 'active_support/all'

module A2A
  # Namespace for Dry::Types definitions
  module Types
    include Dry.Types()

    # Custom type for ISO 8601 DateTime strings
    IsoDateTime = Types::String.constructor do |value|
      case value
      when Time, DateTime
        value.iso8601
      when String
        # Attempt to parse to ensure it's a valid format, then return original string
        begin
          Time.iso8601(value)
          value
        rescue ArgumentError
          # Or raise a specific type error if strict validation is needed upstream
          value # Pass through for now, let struct validation handle if needed
        end
      else
        value
      end
    end

    # Define Nil explicitly for union types where needed
    Nil = Types::Nil
  end

  # Base class for all A2A structures
  class BaseStruct < Dry::Struct
    # Transform keys to symbols if input is string-keyed hash
    transform_keys(&:to_sym)

    # Handle snake_case to camelCase transformation on output if needed
    def to_json(*args)
      to_h.deep_transform_keys { |key| key.to_s.camelize(:lower) }.to_json(*args)
    end
  end

  # --- Agent Card Types ---

  class AgentProvider < BaseStruct
    attribute :organization, Types::Strict::String
    attribute? :url, Types::Strict::String.optional
  end

  class AgentCapabilities < BaseStruct
    attribute :streaming, Types::Strict::Bool.default(false)
    attribute :push_notifications, Types::Strict::Bool.default(false)
    attribute :state_transition_history, Types::Strict::Bool.default(false)
  end

  class AgentAuthentication < BaseStruct
    attribute :schemes, Types::Strict::Array.of(Types::Strict::String)
    attribute? :credentials, Types::Strict::String.optional
  end

  class AgentSkill < BaseStruct
    attribute :id, Types::Strict::String
    attribute :name, Types::Strict::String
    attribute? :description, Types::Strict::String.optional
    attribute? :tags, Types::Strict::Array.of(Types::Strict::String).optional
    attribute? :examples, Types::Strict::Array.of(Types::Strict::String).optional
    attribute? :input_modes, Types::Strict::Array.of(Types::Strict::String).optional
    attribute? :output_modes, Types::Strict::Array.of(Types::Strict::String).optional
  end

  class AgentCard < BaseStruct
    attribute :name, Types::Strict::String
    attribute? :description, Types::Strict::String.optional
    attribute :url, Types::Strict::String
    attribute? :provider, AgentProvider.optional
    attribute :version, Types::Strict::String
    attribute? :documentation_url, Types::Strict::String.optional
    attribute :capabilities, AgentCapabilities
    attribute? :authentication, AgentAuthentication.optional
    attribute :default_input_modes, Types::Strict::Array.of(Types::Strict::String).default(['text'].freeze)
    attribute :default_output_modes, Types::Strict::Array.of(Types::Strict::String).default(['text'].freeze)
    attribute :skills, Types::Strict::Array.of(AgentSkill)
  end

  # --- Core Object Types ---

  class FileContent < BaseStruct
    attribute? :name, Types::Strict::String.optional
    attribute? :mime_type, Types::Strict::String.optional
    attribute? :bytes, Types::Strict::String.optional
    attribute? :uri, Types::Strict::String.optional
  end

  # Part Types (using separate classes)
  class TextPart < BaseStruct
    attribute :type, Types::Strict::String.constrained(eql: 'text').default('text')
    attribute :text, Types::Strict::String
    attribute? :metadata, Types::Strict::Hash.optional
  end

  class FilePart < BaseStruct
    attribute :type, Types::Strict::String.constrained(eql: 'file').default('file')
    attribute :file, FileContent
    attribute? :metadata, Types::Strict::Hash.optional
  end

  class DataPart < BaseStruct
    attribute :type, Types::Strict::String.constrained(eql: 'data').default('data')
    attribute :data, Types::Strict::Hash # Arbitrary JSON data
    attribute? :metadata, Types::Strict::Hash.optional
  end

  # Helper to dynamically create Part instances based on 'type'
  # Assumes input hash keys might be camelCase or snake_case strings/symbols
  def self.create_part(hash)
    # Ensure keys are symbols and snake_cased for internal use
    sym_hash = hash.deep_transform_keys { |key| key.to_s.underscore.to_sym }
    type = sym_hash[:type]
    case type&.to_s
    when 'text'
      TextPart.new(sym_hash) # Pass snake_cased hash
    when 'file'
      FilePart.new(sym_hash)
    when 'data'
      DataPart.new(sym_hash)
    else
      raise ArgumentError, "Unknown Part type: #{type}"
    end
  end


  # Type definition for an array of Parts using the constructor
  PartsArray = Types::Strict::Array.constructor do |arr|
    # Ensure items are hashes before passing to create_part
    # This allows flexibility if the input array contains already-instantiated parts or raw hashes
    arr.map { |item| item.is_a?(Hash) ? A2A.create_part(item) : item }
  end

  class Message < BaseStruct
    attribute :role, Types::Strict::String.enum('user', 'agent')
    attribute :parts, PartsArray # Uses the constructor type above
    attribute? :metadata, Types::Strict::Hash.optional
  end

  # Task State Enum (using constants)
  module TaskState
    SUBMITTED = 'submitted'.freeze
    WORKING = 'working'.freeze
    INPUT_REQUIRED = 'input-required'.freeze
    COMPLETED = 'completed'.freeze
    CANCELED = 'canceled'.freeze
    FAILED = 'failed'.freeze
    UNKNOWN = 'unknown'.freeze
    ALL = [SUBMITTED, WORKING, INPUT_REQUIRED, COMPLETED, CANCELED, FAILED, UNKNOWN].freeze
  end

  class TaskStatus < BaseStruct
    attribute :state, Types::Strict::String.enum(*TaskState::ALL)
    attribute? :message, Message.optional
    attribute :timestamp, Types::IsoDateTime.default { Time.now.iso8601 }
  end

  class Artifact < BaseStruct
    attribute? :name, Types::Strict::String.optional
    attribute? :description, Types::Strict::String.optional
    attribute :parts, PartsArray # Uses the constructor type
    attribute? :metadata, Types::Strict::Hash.optional
    attribute :index, Types::Strict::Integer.default(0)
    attribute? :append, Types::Strict::Bool.optional
    attribute? :last_chunk, Types::Strict::Bool.optional
  end

  class Task < BaseStruct
    attribute :id, Types::Strict::String
    attribute? :session_id, Types::Strict::String.optional
    attribute :status, TaskStatus
    attribute? :artifacts, Types::Strict::Array.of(Artifact).optional
    attribute? :history, Types::Strict::Array.of(Message).optional
    attribute? :metadata, Types::Strict::Hash.optional
  end

  # --- Streaming Event Types ---

  class TaskStatusUpdateEvent < BaseStruct
    attribute :id, Types::Strict::String
    attribute :status, TaskStatus
    attribute :final, Types::Strict::Bool.default(false)
    attribute? :metadata, Types::Strict::Hash.optional
  end

  class TaskArtifactUpdateEvent < BaseStruct
    attribute :id, Types::Strict::String
    attribute :artifact, Artifact
    attribute? :metadata, Types::Strict::Hash.optional
  end

  # --- Push Notification Types ---

  class AuthenticationInfo < BaseStruct
    attribute :schemes, Types::Strict::Array.of(Types::Strict::String)
    attribute? :credentials, Types::Strict::String.optional
  end

  class PushNotificationConfig < BaseStruct
    attribute :url, Types::Strict::String
    attribute? :token, Types::Strict::String.optional
    attribute? :authentication, AuthenticationInfo.optional
  end

  class TaskPushNotificationConfig < BaseStruct
    attribute :id, Types::Strict::String # Task ID
    attribute :push_notification_config, PushNotificationConfig
  end

  # --- JSON-RPC Base Types ---

  class JSONRPCMessage < BaseStruct
    attribute :jsonrpc, Types::Strict::String.constrained(eql: '2.0').default('2.0')
    attribute? :id, (Types::Strict::String | Types::Strict::Integer | Types::Nil).default { SecureRandom.hex }
  end

  class JSONRPCError < BaseStruct
    attribute :code, Types::Strict::Integer
    attribute :message, Types::Strict::String
    attribute? :data, Types::Any
  end

  class JSONRPCRequest < JSONRPCMessage
    attribute :method, Types::Strict::String
    attribute? :params, Types::Strict::Hash.optional
  end

  class JSONRPCResponse < JSONRPCMessage
    attribute? :result, Types::Any
    attribute? :error, JSONRPCError.optional
  end

  # --- Specific RPC Parameter Types ---

  class TaskIdParams < BaseStruct
    attribute :id, Types::Strict::String
    attribute? :metadata, Types::Strict::Hash.optional
  end

  class TaskQueryParams < TaskIdParams
    attribute? :history_length, Types::Strict::Integer.optional
  end

  class TaskSendParams < BaseStruct
    attribute :id, Types::Strict::String # Task ID
    attribute :session_id, Types::Strict::String.default { SecureRandom.hex }
    attribute :message, Message
    attribute? :accepted_output_modes, Types::Strict::Array.of(Types::Strict::String).optional
    attribute? :push_notification, PushNotificationConfig.optional
    attribute? :history_length, Types::Strict::Integer.optional
    attribute? :metadata, Types::Strict::Hash.optional
  end

  # --- Specific RPC Request/Response Types ---

  class SendTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/send').default('tasks/send')
    attribute :params, TaskSendParams
  end

  class SendTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional
  end

  class SendTaskStreamingRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/sendSubscribe').default('tasks/sendSubscribe')
    attribute :params, TaskSendParams
  end

  # Define the possible result types for streaming response
  StreamingResult = Types::Instance(TaskStatusUpdateEvent) | Types::Instance(TaskArtifactUpdateEvent)

  class SendTaskStreamingResponse < JSONRPCResponse
    attribute? :result, (StreamingResult).optional
  end

  class GetTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/get').default('tasks/get')
    attribute :params, TaskQueryParams
  end

  class GetTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional
  end

  class CancelTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/cancel').default('tasks/cancel')
    attribute :params, TaskIdParams
  end

  class CancelTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional
  end

  class SetTaskPushNotificationRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/pushNotification/set').default('tasks/pushNotification/set')
    attribute :params, TaskPushNotificationConfig
  end

  class SetTaskPushNotificationResponse < JSONRPCResponse
    attribute? :result, TaskPushNotificationConfig.optional
  end

  class GetTaskPushNotificationRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/pushNotification/get').default('tasks/pushNotification/get')
    attribute :params, TaskIdParams
  end

  class GetTaskPushNotificationResponse < JSONRPCResponse
    attribute? :result, TaskPushNotificationConfig.optional
  end

  class TaskResubscriptionRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/resubscribe').default('tasks/resubscribe')
    attribute :params, TaskIdParams # Or TaskQueryParams depending on spec interpretation
  end

  # --- Error Types (as Structs for consistency) ---

  class JSONParseError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32700).default(-32700)
    attribute :message, Types::Strict::String.constrained(eql: 'Invalid JSON payload').default('Invalid JSON payload')
  end

  class InvalidRequestError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32600).default(-32600)
    attribute :message, Types::Strict::String.constrained(eql: 'Request payload validation error').default('Request payload validation error')
  end

  class MethodNotFoundError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32601).default(-32601)
    attribute :message, Types::Strict::String.constrained(eql: 'Method not found').default('Method not found')
    attribute? :data, Types::Nil
  end

  class InvalidParamsError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32602).default(-32602)
    attribute :message, Types::Strict::String.constrained(eql: 'Invalid parameters').default('Invalid parameters')
  end

  class InternalError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32603).default(-32603)
    attribute :message, Types::Strict::String.constrained(eql: 'Internal error').default('Internal error')
  end

  class TaskNotFoundError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32001).default(-32001)
    attribute :message, Types::Strict::String.constrained(eql: 'Task not found').default('Task not found')
    attribute? :data, Types::Nil
  end

  class TaskNotCancelableError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32002).default(-32002)
    attribute :message, Types::Strict::String.constrained(eql: 'Task cannot be canceled').default('Task cannot be canceled')
    attribute? :data, Types::Nil
  end

  class PushNotificationNotSupportedError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32003).default(-32003)
    attribute :message, Types::Strict::String.constrained(eql: 'Push Notification is not supported').default('Push Notification is not supported')
    attribute? :data, Types::Nil
  end

  class UnsupportedOperationError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32004).default(-32004)
    attribute :message, Types::Strict::String.constrained(eql: 'This operation is not supported').default('This operation is not supported')
    attribute? :data, Types::Nil
  end

  class ContentTypeNotSupportedError < JSONRPCError
    attribute :code, Types::Strict::Integer.constrained(eql: -32005).default(-32005)
    attribute :message, Types::Strict::String.constrained(eql: 'Incompatible content types').default('Incompatible content types')
    attribute? :data, Types::Nil
  end
end
