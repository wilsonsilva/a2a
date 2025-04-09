# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'
require 'json' # For JSON::Any potentially, though Types::Hash might suffice
require 'time' # For ISO8601 parsing/formatting

# Namespace for all A2A Protocol definitions
module A2A
  # Base module for Dry::Types definitions
  module Types
    include Dry.Types()

    # JSON-RPC ID can be String, Integer, or Nil
    ID = Strict::Integer | Strict::String | Strict::Nil

    # Optional types
    MaybeString = Strict::String | Strict::Nil
    # Use Types::Hash for arbitrary hash structures
    MaybeHash = Hash.optional.default(nil)
    MaybeArrayOfStrings = Types::Array.of(Strict::String).optional.default(nil) # Corrected optional array
    MaybeBool = Strict::Bool | Strict::Nil

    # Timestamp as ISO8601 string
    Timestamp = Strict::String.constrained(format: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[\+\-]\d{2}:\d{2})\z/i)

    # Base64 encoded string
    Base64String = Strict::String

    # Generic metadata hash - MUST accept any hash structure
    # Use the base Hash type, mark as optional, default to nil.
    Metadata = Types::Hash.optional.default(nil)

    # Generic JSON object - MUST accept any hash structure
    # Use the base Hash type.
    JsonObject = Types::Hash

    # Generic JSON data (can be primitive, array, or hash)
    # Using Any is safer if it's truly unknown JSON structure
    JsonData = Types::Any.optional.default(nil) # Using Any allows non-hash JSON too
  end

  # Base class for A2A Structs
  class BaseStruct < Dry::Struct
    # Transform keys to symbols if input is string-keyed hash
    transform_keys(&:to_sym)

    # Handle snake_case to camelCase transformation on output if needed
    def to_json(*args)
      to_h.deep_transform_keys { |key| key.to_s.camelize(:lower) }.to_json(*args)
    end
  end

  # === JSON-RPC Base Structures ===

  # Base for identifying JSON-RPC messages
  class JSONRPCMessageIdentifier < BaseStruct
    attribute? :id, Types::ID
  end

  # Base for all JSON-RPC messages
  class JSONRPCMessage < JSONRPCMessageIdentifier
    attribute? :jsonrpc, Types::String.constrained(eql: '2.0').default('2.0')
  end

  # Represents a JSON-RPC request object base structure
  class JSONRPCRequest < JSONRPCMessage
    attribute :method, Types::Strict::String
    attribute? :params, Types::JsonData # Use flexible JsonData
  end

  # Represents a JSON-RPC error object
  class JSONRPCError < BaseStruct
    attribute :code, Types::Strict::Integer | Types::Strict::String
    attribute :message, Types::Strict::String
    attribute? :data, Types::JsonData # Use flexible JsonData
  end

  # Represents a JSON-RPC response object
  class JSONRPCResponse < JSONRPCMessage
    attribute? :result, Types::JsonData # Use flexible JsonData
    attribute? :error, JSONRPCError.optional.default(nil)
  end

  # === Core A2A Data Structures ===

  # Represents the state of a task within the A2A protocol
  TaskState = Types::Strict::String.enum(
    'submitted',
    'working',
    'input-required',
    'completed',
    'canceled',
    'failed',
    'unknown'
  )

  # Defines the authentication schemes and credentials for an agent
  class AgentAuthentication < BaseStruct
    attribute :schemes, Types::Strict::Array.of(Types::Strict::String)
    attribute? :credentials, Types::MaybeString
  end

  # Describes the capabilities of an agent
  class AgentCapabilities < BaseStruct
    attribute? :streaming, Types::Strict::Bool.default(false)
    attribute? :push_notifications, Types::Strict::Bool.default(false)
    attribute? :state_transition_history, Types::Strict::Bool.default(false)
  end

  # Represents the provider or organization behind an agent
  class AgentProvider < BaseStruct
    attribute :organization, Types::Strict::String
    attribute? :url, Types::MaybeString
  end

  # Defines a specific skill or capability offered by an agent
  class AgentSkill < BaseStruct
    attribute :id, Types::Strict::String
    attribute :name, Types::Strict::String
    attribute? :description, Types::MaybeString
    attribute? :tags, Types::MaybeArrayOfStrings
    attribute? :examples, Types::MaybeArrayOfStrings
    attribute? :input_modes, Types::MaybeArrayOfStrings
    attribute? :output_modes, Types::MaybeArrayOfStrings
  end

  # Represents the metadata card for an agent
  class AgentCard < BaseStruct
    attribute :name, Types::Strict::String
    attribute? :description, Types::MaybeString
    attribute :url, Types::Strict::String
    attribute? :provider, AgentProvider.optional.default(nil)
    attribute :version, Types::Strict::String
    attribute? :documentation_url, Types::MaybeString
    attribute :capabilities, AgentCapabilities
    attribute? :authentication, AgentAuthentication.optional.default(nil)
    attribute? :default_input_modes, Types::Strict::Array.of(Types::Strict::String).default(['text'].freeze)
    attribute? :default_output_modes, Types::Strict::Array.of(Types::Strict::String).default(['text'].freeze)
    attribute :skills, Types::Strict::Array.of(AgentSkill)
  end

  # Base for FileContent variants
  class FileContentBase < BaseStruct
    attribute? :name, Types::MaybeString
    attribute? :mime_type, Types::MaybeString
  end

  # FileContent with Base64 bytes
  class FileContentBytes < FileContentBase
    attribute :bytes, Types::Base64String
    attribute? :uri, Types::Strict::Nil # Must be nil
  end

  # FileContent with a URI
  class FileContentUri < FileContentBase
    attribute :uri, Types::Strict::String
    attribute? :bytes, Types::Strict::Nil # Must be nil
  end

  # Represents the content of a file, either as base64 encoded bytes or a URI.
  FileContent = FileContentBytes | FileContentUri

  # Represents a part of a message containing text content
  class TextPart < BaseStruct
    attribute? :type, Types::Strict::String.constrained(eql: 'text').default('text')
    attribute :text, Types::Strict::String
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents a part of a message containing file content
  class FilePart < BaseStruct
    attribute? :type, Types::Strict::String.constrained(eql: 'file').default('file')
    attribute :file, FileContent
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents a part of a message containing structured data (JSON)
  class DataPart < BaseStruct
    attribute? :type, Types::Strict::String.constrained(eql: 'data').default('data')
    attribute :data, Types::JsonObject # Correct: Use the flexible JsonObject type (which is Types::Hash)
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents a single part of a multi-part message.
  Part = TextPart | FilePart | DataPart

  # Represents an artifact generated or used by a task
  class Artifact < BaseStruct
    attribute? :name, Types::MaybeString
    attribute? :description, Types::MaybeString
    attribute :parts, Types::Strict::Array.of(Part)
    attribute? :index, Types::Strict::Integer.default(0)
    attribute? :append, Types::MaybeBool
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
    attribute? :last_chunk, Types::MaybeBool
  end

  # Represents a message exchanged between a user and an agent
  class Message < BaseStruct
    attribute :role, Types::Strict::String.enum('user', 'agent')
    attribute :parts, Types::Strict::Array.of(Part)
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents the status of a task at a specific point in time
  class TaskStatus < BaseStruct
    attribute :state, TaskState
    attribute? :message, Message.optional.default(nil)
    attribute? :timestamp, Types::JSON::Time.default { Time.now.utc }
  end

  # Represents a task being processed by an agent
  class Task < BaseStruct
    attribute :id, Types::Strict::String
    attribute? :session_id, Types::MaybeString
    attribute :status, TaskStatus
    attribute? :artifacts, Types::Strict::Array.of(Artifact).optional.default(nil)
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents the history of messages exchanged within a task's session.
  class TaskHistory < BaseStruct
    attribute? :message_history, Types::Strict::Array.of(Message).default([].freeze)
  end

  # Represents a status update event for a task
  class TaskStatusUpdateEvent < BaseStruct
    attribute :id, Types::Strict::String
    attribute :status, TaskStatus
    attribute? :final, Types::Strict::Bool.default(false)
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Represents an artifact update event for a task
  class TaskArtifactUpdateEvent < BaseStruct
    attribute :id, Types::Strict::String
    attribute :artifact, Artifact
    attribute? :final, Types::Strict::Bool.default(false) # Included for consistency
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Alias for backward compatibility (if needed)
  TaskUpdateEvent = TaskStatusUpdateEvent

  # === Error Types (Standard and A2A) ===

  # Standard JSON-RPC Error Codes
  ErrorCodeParseError = -32700
  ErrorCodeInvalidRequest = -32600
  ErrorCodeMethodNotFound = -32601
  ErrorCodeInvalidParams = -32602
  ErrorCodeInternalError = -32603

  # A2A Specific Error Codes (within Server error range)
  ErrorCodeTaskNotFound = -32001
  ErrorCodeTaskNotCancelable = -32002
  ErrorCodePushNotificationNotSupported = -32003
  ErrorCodeUnsupportedOperation = -32004

  # Union of all well-known error codes defined here
  KnownErrorCode = Types::Strict::Integer.enum(
    ErrorCodeParseError,
    ErrorCodeInvalidRequest,
    ErrorCodeMethodNotFound,
    ErrorCodeInvalidParams,
    ErrorCodeInternalError,
    ErrorCodeTaskNotFound,
    ErrorCodeTaskNotCancelable,
    ErrorCodePushNotificationNotSupported,
    ErrorCodeUnsupportedOperation
  )

  # Type alias for A2A errors, allowing known codes or other integers
  A2AError = JSONRPCError.constructor do |value|
    # Ensure value is a Hash before accessing keys
    value = value.to_h if value.respond_to?(:to_h)
    if value.is_a?(Hash) && value.key?(:code)
      begin
        # Try to coerce known code, fallback to original code if it fails or isn't known
        original_code = value[:code]
        value[:code] = KnownErrorCode[original_code] rescue original_code
      rescue TypeError
        # Keep original code if it's not an integer/coercible
      end
    end
    JSONRPCError.new(value)
  end

  # === Push Notifications and Authentication Info ===

  # Authentication information
  # Default struct behavior ignores extra keys. No need for `passthrough` here.
  class AuthenticationInfo < AgentAuthentication
    # Inherits schemes, credentials from AgentAuthentication
  end

  # Information required for setting up push notifications
  class PushNotificationConfig < BaseStruct
    attribute :url, Types::Strict::String
    attribute? :token, Types::MaybeString
    attribute? :authentication, AuthenticationInfo.optional.default(nil)
  end

  # Represents the push notification information associated with a specific task ID
  class TaskPushNotificationConfig < BaseStruct
    attribute :id, Types::Strict::String # Task ID
    attribute :push_notification_config, PushNotificationConfig
  end

  # === A2A Request Parameter Types ===

  # Parameters for the `tasks/send` method
  class TaskSendParams < BaseStruct
    attribute :id, Types::Strict::String
    attribute? :session_id, Types::MaybeString
    attribute :message, Message
    attribute? :push_notification, PushNotificationConfig.optional.default(nil)
    attribute? :history_length, Types::Strict::Integer.optional.default(nil)
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Basic parameters used for task ID operations
  class TaskIdParams < BaseStruct
    attribute :id, Types::Strict::String
    attribute? :metadata, Types::Metadata # Correct: Use the flexible Metadata type
  end

  # Parameters used for querying task-related information by ID
  class TaskQueryParams < TaskIdParams
    attribute? :history_length, Types::Strict::Integer.optional.default(nil)
  end

  # === A2A Request Interfaces ===
  # (Requests remain the same, referencing corrected param types)

  class SendTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/send').default('tasks/send')
    attribute :params, TaskSendParams
  end

  class GetTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/get').default('tasks/get')
    attribute :params, TaskQueryParams
  end

  class CancelTaskRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/cancel').default('tasks/cancel')
    attribute :params, TaskIdParams
  end

  class SetTaskPushNotificationRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/pushNotification/set').default('tasks/pushNotification/set')
    attribute :params, TaskPushNotificationConfig
  end

  class GetTaskPushNotificationRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/pushNotification/get').default('tasks/pushNotification/get')
    attribute :params, TaskIdParams
  end

  class TaskResubscriptionRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/resubscribe').default('tasks/resubscribe')
    attribute :params, TaskQueryParams
  end

  class SendTaskStreamingRequest < JSONRPCRequest
    attribute :method, Types::Strict::String.constrained(eql: 'tasks/sendSubscribe').default('tasks/sendSubscribe')
    attribute :params, TaskSendParams
  end

  # === A2A Response Interfaces ===
  # (Responses remain the same, referencing corrected result/error types)

  class SendTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional.default(nil)
    attribute? :error, A2AError.optional.default(nil)
  end

  StreamingResult = TaskStatusUpdateEvent | TaskArtifactUpdateEvent | Types::Strict::Nil
  class SendTaskStreamingResponse < JSONRPCResponse
    attribute? :result, StreamingResult
    attribute? :error, A2AError.optional.default(nil)
  end

  class GetTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional.default(nil)
    attribute? :error, A2AError.optional.default(nil)
  end

  class CancelTaskResponse < JSONRPCResponse
    attribute? :result, Task.optional.default(nil)
    attribute? :error, A2AError.optional.default(nil)
  end

  class SetTaskPushNotificationResponse < JSONRPCResponse
    attribute? :result, TaskPushNotificationConfig.optional.default(nil)
    attribute? :error, A2AError.optional.default(nil)
  end

  class GetTaskPushNotificationResponse < JSONRPCResponse
    attribute? :result, TaskPushNotificationConfig.optional.default(nil)
    attribute? :error, A2AError.optional.default(nil)
  end
end
