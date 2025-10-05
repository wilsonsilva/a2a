# frozen_string_literal: true

module A2A
  # A discriminated union representing all possible JSON-RPC 2.0 requests supported by the A2A specification.
  Request = SendMessageRequest |
            SendStreamingMessageRequest |
            GetTaskRequest |
            CancelTaskRequest |
            SetTaskPushNotificationConfigRequest |
            GetTaskPushNotificationConfigRequest |
            TaskResubscriptionRequest |
            ListTaskPushNotificationConfigRequest |
            DeleteTaskPushNotificationConfigRequest |
            GetAuthenticatedExtendedCardRequest
end
