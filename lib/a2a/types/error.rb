# frozen_string_literal: true

module A2A
  # A discriminated union of all standard JSON-RPC and A2A-specific error types.
  Error = Types.Constructor(
    Types.Instance(JSONRPC::ParseError) |
    Types.Instance(JSONRPC::InvalidRequestError) |
    Types.Instance(JSONRPC::MethodNotFoundError) |
    Types.Instance(JSONRPC::InvalidParamsError) |
    Types.Instance(JSONRPC::InternalError) |
    Types.Instance(TaskNotFoundError) |
    Types.Instance(TaskNotCancelableError) |
    Types.Instance(PushNotificationNotSupportedError) |
    Types.Instance(UnsupportedOperationError) |
    Types.Instance(ContentTypeNotSupportedError) |
    Types.Instance(InvalidAgentResponseError) |
    Types.Instance(AuthenticatedExtendedCardNotConfiguredError)
  ) { |value| value }
end
