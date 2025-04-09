# frozen_string_literal: true

module A2A
  module Schema
    # Helper to create a JSON-RPC success response
    # @param id [String, Integer, nil] Response ID matching request
    # @param result [Object] Result value
    # @return [JSONRPCResponse] Success response
    def self.json_rpc_success(id, result)
      JSONRPCResponse.new(id: id, result: result)
    end

    # Helper to create a JSON-RPC error response
    # @param id [String, Integer, nil] Response ID matching request
    # @param error [JSONRPCError] Error object
    # @return [JSONRPCResponse] Error response
    def self.json_rpc_error(id, error)
      JSONRPCResponse.new(id: id, error: error)
    end

    # Create a Part object from a hash
    # @param hash [Hash] Hash containing part data
    # @return [Part] The appropriate Part subclass instance
    def self.part_from_hash(hash)
      type = hash['type'] || (hash['text'] ? 'text' : nil) ||
        (hash['file'] ? 'file' : nil) || (hash['data'] ? 'data' : nil)

      metadata = hash['metadata']

      case type
      when 'text'
        TextPart.new(text: hash['text'], metadata: metadata)
      when 'file'
        FilePart.new(file: hash['file'], metadata: metadata)
      when 'data'
        DataPart.new(data: hash['data'], metadata: metadata)
      else
        raise ArgumentError, "Unknown part type: #{type}"
      end
    end

    # Create a Message object from a hash
    # @param hash [Hash] Hash containing message data
    # @return [Message] The created Message instance
    def self.message_from_hash(hash)
      parts = hash['parts'].map { |p| part_from_hash(p) }

      Message.new(
        role: hash['role'],
        parts: parts,
        metadata: hash['metadata']
      )
    end

    # Create an Artifact object from a hash
    # @param hash [Hash] Hash containing artifact data
    # @return [Artifact] The created Artifact instance
    def self.artifact_from_hash(hash)
      parts = hash['parts'].map { |p| part_from_hash(p) }

      Artifact.new(
        name: hash['name'],
        description: hash['description'],
        parts: parts,
        metadata: hash['metadata'],
        index: hash['index'],
        append: hash['append'],
        last_chunk: hash['lastChunk'] || hash['last_chunk']
      )
    end

    # Create a TaskStatus object from a hash
    # @param hash [Hash] Hash containing task status data
    # @return [TaskStatus] The created TaskStatus instance
    def self.task_status_from_hash(hash)
      message = hash['message'] ? message_from_hash(hash['message']) : nil

      TaskStatus.new(
        state: hash['state'],
        message: message,
        timestamp: hash['timestamp'] ? Time.parse(hash['timestamp']) : nil
      )
    end

    # Create a Task object from a hash
    # @param hash [Hash] Hash containing task data
    # @return [Task] The created Task instance
    def self.task_from_hash(hash)
      status = task_status_from_hash(hash['status'])
      artifacts = hash['artifacts']&.map { |a| artifact_from_hash(a) }

      Task.new(
        id: hash['id'],
        session_id: hash['sessionId'] || hash['session_id'],
        status: status,
        artifacts: artifacts,
        metadata: hash['metadata']
      )
    end

    # Create a TaskSendParams object from a hash
    # @param hash [Hash] Hash containing task send params
    # @return [TaskSendParams] The created TaskSendParams instance
    def self.task_send_params_from_hash(hash)
      message = message_from_hash(hash['message'])
      push_notification = hash['pushNotification'] || hash['push_notification']

      if push_notification
        push_notification = PushNotificationConfig.new(
          url: push_notification['url'],
          token: push_notification['token'],
          authentication: push_notification['authentication']
        )
      end

      TaskSendParams.new(
        id: hash['id'],
        session_id: hash['sessionId'] || hash['session_id'],
        message: message,
        push_notification: push_notification,
        history_length: hash['historyLength'] || hash['history_length'],
        metadata: hash['metadata']
      )
    end

    # Create a TaskQueryParams object from a hash
    # @param hash [Hash] Hash containing task query params
    # @return [TaskQueryParams] The created TaskQueryParams instance
    def self.task_query_params_from_hash(hash)
      TaskQueryParams.new(
        id: hash['id'],
        history_length: hash['historyLength'] || hash['history_length'],
        metadata: hash['metadata']
      )
    end

    # Create a TaskIdParams object from a hash
    # @param hash [Hash] Hash containing task ID params
    # @return [TaskIdParams] The created TaskIdParams instance
    def self.task_id_params_from_hash(hash)
      TaskIdParams.new(
        id: hash['id'],
        metadata: hash['metadata']
      )
    end
  end
end