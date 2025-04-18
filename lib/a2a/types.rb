# frozen_string_literal: true

require 'dry-struct'
require 'dry-types'
require 'dry/inflector'
require 'json'
require_relative 'types/with_additional_properties'

module A2A
  # @!visibility private
  module Types
    include Dry.Types()

    Dry::Types.define_builder(:constant) { |type, value| type.default(value).enum(value) }
  end

  # Base class for all A2A struct objects
  # @!visibility private
  class ProtocolStruct < Dry::Struct
    include Types::WithCaseTransformation
  end

  # Defines the authentication schemes and credentials for an agent.
  class AgentAuthentication < ProtocolStruct
    # @return [Array<String>] List of supported authentication schemes.
    attribute :schemes, Types::Array.of(Types::String)

    # @return [String, nil] Credentials for authentication. Can be a string (e.g., token) or null if not
    # required initially.
    attribute? :credentials, Types::String.optional
  end

  # Describes the capabilities of an agent.
  class AgentCapabilities < ProtocolStruct
    # @return [Boolean] Indicates if the agent supports streaming responses.
    attribute? :streaming, Types::Bool.default(false)

    # @return [Boolean] Indicates if the agent supports push notification mechanisms.
    attribute? :push_notifications, Types::Bool.default(false)

    # @return [Boolean] Indicates if the agent supports providing state transition history.
    attribute? :state_transition_history, Types::Bool.default(false)
  end

  # Represents the provider or organization behind an agent.
  class AgentProvider < ProtocolStruct
    # @return [String] The name of the organization providing the agent.
    attribute :organization, Types::String

    # @return [String, nil] URL associated with the agent provider.
    attribute? :url, Types::String.optional
  end

  # Defines a specific skill or capability offered by an agent.
  class AgentSkill < ProtocolStruct
    # @return [String] Unique identifier for the skill.
    attribute :id, Types::String

    # @return [String] Human-readable name of the skill.
    attribute :name, Types::String

    # @return [String, nil] Optional description of the skill.
    attribute? :description, Types::String.optional

    # @return [Array<String>, nil] Optional list of tags associated with the skill for categorization.
    attribute? :tags, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of example inputs or use cases for the skill.
    attribute? :examples, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of input modes supported by this skill, overriding agent defaults.
    attribute? :input_modes, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of output modes supported by this skill, overriding agent defaults.
    attribute? :output_modes, Types::Array.of(Types::String).optional
  end

  # Represents the metadata card for an agent, describing its properties and capabilities.
  class AgentCard < ProtocolStruct
    # @return [String] The name of the agent.
    attribute :name, Types::String

    # @return [String, nil] An optional description of the agent.
    attribute? :description, Types::String.optional

    # @return [String] The base URL endpoint for interacting with the agent.
    attribute :url, Types::String

    # @return [AgentProvider, nil] Information about the provider of the agent.
    attribute? :provider, Types::Constructor(AgentProvider).optional

    # @return [String] The version identifier for the agent or its API.
    attribute :version, Types::String

    # @return [String, nil] An optional URL pointing to the agent's documentation.
    attribute? :documentation_url, Types::String.optional

    # @return [AgentCapabilities] The capabilities supported by the agent.
    attribute :capabilities, Types::Constructor(AgentCapabilities)

    # @return [AgentAuthentication, nil] Authentication details required to interact with the agent.
    attribute? :authentication, Types::Constructor(AgentAuthentication).optional

    # @return [Array<String>] Default input modes supported by the agent (e.g., 'text', 'file', 'json').
    attribute? :default_input_modes, Types::Array.of(Types::String).default(['text'].freeze)

    # @return [Array<String>] Default output modes supported by the agent (e.g., 'text', 'file', 'json').
    attribute? :default_output_modes, Types::Array.of(Types::String).default(['text'].freeze)

    # @return [Array<AgentSkill>] List of specific skills offered by the agent.
    attribute :skills, Types::Array.of(Types::Constructor(AgentSkill))
  end

  # Represents the content of a file, either as base64 encoded bytes or a URI.
  class FileContent < ProtocolStruct
    # @return [String, nil] Optional name of the file.
    attribute? :name, Types::String.optional

    # @return [String, nil] Optional MIME type of the file content.
    attribute? :mime_type, Types::String.optional

    # @return [String, nil] File content encoded as a Base64 string. Use this OR `uri`.
    attribute? :bytes, Types::String.optional

    # @return [String, nil] URI pointing to the file content. Use this OR `bytes`.
    attribute? :uri, Types::String.optional
  end

  # Represents a part of a message containing text content.
  class TextPart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('text')

    # @return [String] The text content.
    attribute :text, Types::String

    # @return [Hash, nil] Optional metadata associated with this text part.
    attribute? :metadata, Types::Hash.optional
  end

  # Represents a part of a message containing file content.
  class FilePart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('file')

    # @return [FileContent] The file content, provided either inline or via URI.
    attribute :file, Types::Constructor(FileContent)

    # @return [Hash, nil] Optional metadata associated with this file part.
    attribute? :metadata, Types::Hash.optional
  end

  # Represents a part of a message containing structured data (JSON).
  class DataPart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('data')

    # @return [Hash] The structured data content as a JSON object.
    attribute :data, Types::Hash

    # @return [Hash, nil] Optional metadata associated with this data part.
    attribute? :metadata, Types::Hash.optional
  end

  # Represents a single part of a multi-part message. Can be text, file, or data.
  Part = TextPart | FilePart | DataPart

  # Represents a message exchanged between a user and an agent.
  class Message < ProtocolStruct
    # @return [String] The role of the sender (user or agent).
    attribute :role, Types::String.enum('user', 'agent')

    # @return [Array<Part>] The content of the message, composed of one or more parts.
    attribute :parts, Types::Array.of(Types::Constructor(Part))

    # @return [Hash, nil] Optional metadata associated with the message.
    attribute? :metadata, Types::Hash.optional
  end

  # The current state of the task
  TaskState = Types::String.enum('submitted', 'working', 'input-required', 'completed', 'canceled', 'failed', 'unknown')

  # Represents the status of a task at a specific point in time.
  class TaskStatus < ProtocolStruct
    # @return [String] The current state of the task.
    attribute :state, TaskState

    # @return [Message, nil] An optional message associated with the current status.
    attribute? :message, Types::Constructor(Message).optional

    # @return [DateTime, nil] The timestamp when this status was recorded (ISO 8601 format).
    attribute? :timestamp, Types::JSON::DateTime.optional
  end

  # Represents an artifact generated or used by a task, potentially composed of multiple parts.
  class Artifact < ProtocolStruct
    # @return [String, nil] Optional name for the artifact.
    attribute? :name, Types::String.optional

    # @return [String, nil] Optional description of the artifact.
    attribute? :description, Types::String.optional

    # @return [Array<Part>] The constituent parts of the artifact.
    attribute :parts, Types::Array.of(Types::Constructor(Part))

    # @return [Integer, nil] Optional index for ordering artifacts, especially relevant in streaming or updates.
    attribute? :index, Types::Integer.default(0)

    # @return [Boolean, nil] Optional flag indicating if this artifact content should append to previous
    # content (for streaming).
    attribute? :append, Types::Bool.optional

    # @return [Hash, nil] Optional metadata associated with the artifact.
    attribute? :metadata, Types::Hash.optional

    # @return [Boolean, nil] Optional flag indicating if this is the last chunk of data for this
    # artifact (for streaming).
    attribute? :last_chunk, Types::Bool.optional
  end

  # Represents a task being processed by an agent.
  class Task < ProtocolStruct
    # @return [String] Unique identifier for the task.
    attribute :id, Types::String

    # @return [String, nil] Optional identifier for the session this task belongs to.
    attribute? :session_id, Types::String.optional

    # @return [TaskStatus] The current status of the task.
    attribute :status, Types::Constructor(TaskStatus)

    # @return [Array<Artifact>, nil] Optional list of artifacts associated with the task
    # (e.g., outputs, intermediate files).
    attribute? :artifacts, Types::Array.of(Types::Constructor(Artifact)).optional

    # @return [Array<Message>, nil] Optional history of messages exchanged during the task.
    attribute? :history, Types::Array.of(Types::Constructor(Message)).optional

    # @return [Hash, nil] Optional metadata associated with the task.
    attribute? :metadata, Types::Hash.optional
  end

  # Parameters for the `tasks/send` method.
  class TaskSendParams < ProtocolStruct
    # @return [String] Unique identifier for the task being initiated or continued.
    attribute :id, Types::String

    # @return [String, nil] Optional identifier for the session this task belongs to. If not provided, a new
    # session might be implicitly created depending on the agent.
    attribute? :session_id, Types::String.optional

    # @return [Message] The message content to send to the agent for processing.
    attribute :message, Types::Constructor(Message)

    # @return [PushNotificationConfig, nil] Optional pushNotification information for receiving notifications about
    # this task. Requires agent capability.
    attribute? :push_notification, Types::Constructor(PushNotificationConfig).optional

    # @return [Integer, nil] Optional parameter to specify how much message history to include in the response.
    attribute? :history_length, Types::Integer.optional

    # @return [Hash, nil] Optional metadata associated with sending this message.
    attribute? :metadata, Types::Hash.optional
  end

  # Basic parameters used for task ID operations.
  class TaskIdParams < ProtocolStruct
    # @return [String] The unique identifier of the task.
    attribute :id, Types::String

    # @return [Hash, nil] Optional metadata to include with the operation.
    attribute? :metadata, Types::Hash.optional
  end

  # Parameters used for querying task-related information by ID.
  class TaskQueryParams < TaskIdParams
    # @return [Integer, nil] Optional history length to retrieve for the task.
    attribute? :history_length, Types::Integer.optional
  end

  # Information required for setting up push notifications.
  class PushNotificationConfig < ProtocolStruct
    # @return [String] The URL endpoint where the agent should send notifications.
    attribute :url, Types::String

    # @return [String, nil] A token to be included in push notification requests for verification/authentication.
    attribute? :token, Types::String.optional

    # @return [AuthenticationInfo, nil] Optional authentication details needed by the agent to call the notification URL.
    attribute? :authentication, Types::Constructor(AuthenticationInfo).optional
  end

  # Represents the push notification information associated with a specific task ID.
  class TaskPushNotificationConfig < ProtocolStruct
    # @return [String] The ID of the task the notification config is associated with.
    attribute :id, Types::String

    # @return [PushNotificationConfig] The push notification configuration details.
    attribute :push_notification_config, Types::Constructor(PushNotificationConfig)
  end

  # Represents a status update event for a task, typically used in streaming scenarios.
  class TaskStatusUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task being updated.
    attribute :id, Types::String

    # @return [TaskStatus] The new status of the task.
    attribute :status, Types::Constructor(TaskStatus)

    # @return [Boolean] Flag indicating if this is the final update for the task.
    attribute? :final, Types::Bool.default(false)

    # @return [Hash, nil] Optional metadata associated with this update event.
    attribute? :metadata, Types::Hash.optional
  end

  # Represents an artifact update event for a task, typically used in streaming scenarios.
  class TaskArtifactUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task being updated.
    attribute :id, Types::String

    # @return [Artifact] The new or updated artifact for the task.
    attribute :artifact, Types::Constructor(Artifact)

    # @return [Boolean, nil] Flag indicating if this is the final update for the task.
    attribute? :final, Types::Bool.optional

    # @return [Hash, nil] Optional metadata associated with this update event.
    attribute? :metadata, Types::Hash.optional
  end

  # Represents a base message for JSON-RPC communication.
  class JSONRPCMessage < ProtocolStruct
    # @return [String] Specifies the JSON-RPC version. Must be "2.0".
    attribute? :jsonrpc, Types::String.constant('2.0')

    # @return [Integer, String, nil] Request identifier. Responses must have the same ID as the request they relate to.
    attribute? :id, (Types::Integer | Types::String).optional
  end

  # Represents a JSON-RPC request object.
  class JSONRPCRequest < JSONRPCMessage
    # @return [String] The name of the method to be invoked.
    attribute :method, Types::String

    # @return [Hash, nil] Parameters for the method. Can be a structured object, an array, or null/omitted.
    attribute? :params, Types::Hash.optional

    # @return [String] The name of the method to be invoked.
    def method = attributes[:method]
  end

  # Represents a JSON-RPC error object.
  class JSONRPCError < ProtocolStruct
    # @return [Integer] A number indicating the error type that occurred.
    attribute :code, Types::Integer.constant(ErrorCodes::PARSE_ERROR)

    # @return [String] A string providing a short description of the error.
    attribute :message, Types::String.constant('Invalid JSON payload')

    # @return [Object, nil] Optional additional data about the error.
    attribute? :data, Types::Nominal::Any.optional
  end

  # Represents a JSON-RPC response object.
  class JSONRPCResponse < JSONRPCMessage
    # @return [Object, nil] The result of the method invocation. Required on success.
    attribute? :result, Types::Nominal::Any.optional

    # @return [JSONRPCError, nil] An error object if an error occurred during the request. Required on failure.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Request to send a message/initiate a task.
  class SendTaskRequest < JSONRPCRequest
    # @return [String] Method name for sending a task message.
    attribute :method, Types::String.constant('tasks/send')

    # @return [TaskSendParams] Parameters for the send task method.
    attribute :params, Types::Constructor(TaskSendParams)

    # @return [String] The name of the method to be invoked.
    def method = attributes[:method]
  end

  # Request to retrieve the current state of a task.
  class GetTaskRequest < JSONRPCRequest
    # @return [String] Method name for getting task status.
    attribute :method, Types::String.constant('tasks/get')

    # @return [TaskQueryParams] Parameters for the get task method.
    attribute :params, Types::Constructor(TaskQueryParams)

    # @return [String] Method name for getting task status.
    def method = attributes[:method]
  end

  # Request to cancel a currently running task.
  class CancelTaskRequest < JSONRPCRequest
    # @return [String] Method name for canceling a task.
    attribute :method, Types::String.constant('tasks/cancel')

    # @return [TaskIdParams] Parameters for the cancel task method.
    attribute :params, Types::Constructor(TaskIdParams)

    # @return [String] Method name for canceling a task.
    def method = attributes[:method]
  end

  # Request to set or update the push notification config for a task.
  class SetTaskPushNotificationRequest < JSONRPCRequest
    # @return [String] Method name for setting a task notifications.
    attribute :method, Types::String.constant('tasks/pushNotification/set')

    # @return [TaskPushNotificationConfig] Parameters for the set task push notification method.
    attribute :params, Types::Constructor(TaskPushNotificationConfig)

    # @return [String] Method name for setting a task notifications.
    def method = attributes[:method]
  end

  # Request to retrieve the currently configured push notification configuration for a task.
  class GetTaskPushNotificationRequest < JSONRPCRequest
    # @return [String] Method name for getting task notification configuration.
    attribute :method, Types::String.constant('tasks/pushNotification/get')

    # @return [TaskIdParams] Parameters for the get task push notification config method.
    attribute :params, Types::Constructor(TaskIdParams)

    # @return [String] Method name for getting task notification configuration.
    def method = attributes[:method]
  end

  # Request to resubscribe to updates for a task after a connection interruption.
  class TaskResubscriptionRequest < JSONRPCRequest
    # @return [String] Method name for resubscribing to task updates.
    attribute :method, Types::String.constant('tasks/resubscribe')

    # @return [TaskQueryParams] Parameters for the task resubscription method.
    attribute :params, Types::Constructor(TaskQueryParams)

    # @return [String] Method name for resubscribing to task updates.
    def method = attributes[:method]
  end

  # Request to send a message/initiate a task and subscribe to streaming updates.
  class SendTaskStreamingRequest < JSONRPCRequest
    # @return [String] Method name for sending a task message and subscribing to updates.
    attribute :method, Types::String.constant('tasks/sendSubscribe')

    # @return [TaskSendParams] Parameters for the streaming task send method.
    attribute :params, Types::Constructor(TaskSendParams)

    # @return [String] Method name for sending a task message and subscribing to updates.
    def method = attributes[:method]
  end

  # Response to a `tasks/send` request.
  # Contains the Task object or an error.
  class SendTaskResponse < JSONRPCResponse
    # @return [Task, nil] The resulting task if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Response to a streaming task operation, either through `tasks/sendSubscribe` or a subscription.
  # Contains a TaskStatusUpdateEvent, TaskArtifactUpdateEvent, or an error.
  class SendTaskStreamingResponse < JSONRPCResponse
    # @return [TaskStatusUpdateEvent, TaskArtifactUpdateEvent, nil] Event data if successful.
    attribute? :result do
      Types.Constructor(TaskStatusUpdateEvent) | Types.Constructor(TaskArtifactUpdateEvent)
    end.optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Response to a `tasks/get` request. Contains the Task object or an error.
  class GetTaskResponse < JSONRPCResponse
    # @return [Task, nil] The task information if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Response to a `tasks/cancel` request. Contains the updated Task object or an error.
  class CancelTaskResponse < JSONRPCResponse
    # @return [Task, nil] The canceled task information if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Response to a `tasks/pushNotification/set` request. Contains the TaskPushNotificationConfig or an error.
  class SetTaskPushNotificationResponse < JSONRPCResponse
    # @return [TaskPushNotificationConfig, nil] The push notification config if successful.
    attribute? :result, Types::Constructor(TaskPushNotificationConfig).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Response to a `tasks/pushNotification/get` request. Contains the TaskPushNotificationConfig or an error.
  class GetTaskPushNotificationResponse < JSONRPCResponse
    # @return [TaskPushNotificationConfig, nil] The push notification config if successful.
    attribute? :result, Types::Constructor(TaskPushNotificationConfig).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end

  # Authentication information, potentially including additional properties beyond the standard ones.
  # (Note: Schema allows additional properties).
  class AuthenticationInfo < AgentAuthentication
    include Types::WithAdditionalProperties
  end

  # Standard JSON-RPC error codes
  module ErrorCodes
    # Invalid JSON was received by the server
    PARSE_ERROR = -32_700
    # The JSON sent is not a valid Request object
    INVALID_REQUEST = -32_600
    # The method does not exist / is not available
    METHOD_NOT_FOUND = -32_601
    # Invalid method parameter(s)
    INVALID_PARAMS = -32_602
    # Internal JSON-RPC error
    INTERNAL_ERROR = -32_603

    # The specified task was not found
    TASK_NOT_FOUND = -32_001
    # The specified task cannot be canceled
    TASK_NOT_CANCELABLE = -32_002
    # Push Notifications are not supported for this operation or agent
    PUSH_NOTIFICATION_NOT_SUPPORTED = -32_003
    # The requested operation is not supported by the agent
    UNSUPPORTED_OPERATION = -32_004
  end

  # Common error classes for the A2A protocol

  # Error for invalid JSON payload
  class JSONParseError < JSONRPCError
    # @return [Integer] Error code (-32700)
    attribute :code, Types::Integer.constant(ErrorCodes::PARSE_ERROR)

    # @return [String] Error message
    attribute :message, Types::String.constant('Invalid JSON payload')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end

  # Error for invalid request structure
  class InvalidRequestError < JSONRPCError
    # @return [Integer] Error code (-32600)
    attribute :code, Types::Integer.constant(ErrorCodes::INVALID_REQUEST)

    # @return [String] Error message
    attribute :message, Types::String.constant('Request payload validation error')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end

  # Error for method not found
  class MethodNotFoundError < JSONRPCError
    # @return [Integer] Error code (-32601)
    attribute :code, Types::Integer.constant(ErrorCodes::METHOD_NOT_FOUND)

    # @return [String] Error message
    attribute :message, Types::String.constant('Method not found')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end

  # Error for invalid parameters
  class InvalidParamsError < JSONRPCError
    # @return [Integer] Error code (-32602)
    attribute :code, Types::Integer.constant(ErrorCodes::INVALID_PARAMS)

    # @return [String] Error message
    attribute :message, Types::String.constant('Invalid parameters')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end

  # Error for internal server errors
  class InternalError < JSONRPCError
    # @return [Integer] Error code (-32603)
    attribute :code, Types::Integer.constant(ErrorCodes::INTERNAL_ERROR)

    # @return [String] Error message
    attribute :message, Types::String.constant('Internal error')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end

  # Error for task not found
  class TaskNotFoundError < JSONRPCError
    # @return [Integer] Error code (-32001)
    attribute :code, Types::Integer.constant(ErrorCodes::TASK_NOT_FOUND)

    # @return [String] Error message
    attribute :message, Types::String.constant('Task not found')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end

  # Error for task not cancelable
  class TaskNotCancelableError < JSONRPCError
    # @return [Integer] Error code (-32002)
    attribute :code, Types::Integer.constant(ErrorCodes::TASK_NOT_CANCELABLE)

    # @return [String] Error message
    attribute :message, Types::String.constant('Task cannot be canceled')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end

  # Error for push notification not supported
  class PushNotificationNotSupportedError < JSONRPCError
    # @return [Integer] Error code (-32003)
    attribute :code, Types::Integer.constant(ErrorCodes::PUSH_NOTIFICATION_NOT_SUPPORTED)

    # @return [String] Error message
    attribute :message, Types::String.constant('Push Notification is not supported')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end

  # Error for unsupported operations
  class UnsupportedOperationError < JSONRPCError
    # @return [Integer] Error code (-32004)
    attribute :code, Types::Integer.constant(ErrorCodes::UNSUPPORTED_OPERATION)

    # @return [String] Error message
    attribute :message, Types::String.constant('This operation is not supported')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end
end
