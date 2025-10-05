# frozen_string_literal: true

module A2A
  # Response to a `tasks/pushNotificationConfig/delete` request.
  # Returns null on successful deletion.
  class DeleteTaskPushNotificationConfigResponse < JSONRPC::Response
    # @return [NilClass, nil] Returns null on successful deletion.
    attribute? :result, Types::Nil.optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
