# frozen_string_literal: true

module A2A
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
end
