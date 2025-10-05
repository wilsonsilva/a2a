# TypeScript to Ruby A2A Type Mapping

## Design Philosophy

The Ruby implementation follows a **consolidated approach** rather than direct TypeScript translation, favoring:
- **Inheritance and polymorphism** over separate interfaces for success/error cases
- **Fewer, more flexible classes** over granular type separation
- **Ruby idioms** like `success?`/`error?` methods over type-based discrimination

## Legend
- ✅ **Direct mapping** - 1:1 TypeScript interface to Ruby class
- 🔄 **Consolidated mapping** - Multiple TypeScript types handled by one Ruby class
- 📝 **Design choice** - Intentional architectural difference

## Core JSON-RPC Types

| TypeScript Type | Ruby Equivalent | Status | Notes |
|-----------------|-----------------|--------|-------|
| `JSONRPCError` | `JSONRPC::Error` | ✅ Direct mapping | |
| `JSONRPCMessage` | `JSONRPC::Request` + `JSONRPC::Response` | 🔄 **Consolidated** | Ruby uses separate Request/Response base classes |
| `JSONRPCRequest` | `JSONRPC::Request` | ✅ Direct mapping | |
| `JSONRPCSuccessResponse` | `JSONRPC::Response` (when `result` present) | 🔄 **Polymorphic** | Use `response.success?` method |
| `JSONRPCErrorResponse` | `JSONRPC::Response` (when `error` present) | 🔄 **Polymorphic** | Use `response.error?` method |

## Standard JSON-RPC Errors

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `JSONParseError` | `JSONRPC::ParseError` | ✅ Direct mapping |
| `InvalidRequestError` | `JSONRPC::InvalidRequestError` | ✅ Direct mapping |
| `MethodNotFoundError` | `JSONRPC::MethodNotFoundError` | ✅ Direct mapping |
| `InvalidParamsError` | `JSONRPC::InvalidParamsError` | ✅ Direct mapping |
| `InternalError` | `JSONRPC::InternalError` | ✅ Direct mapping |

## A2A-Specific Errors

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `TaskNotFoundError` | `A2A::TaskNotFoundError` | ✅ Direct mapping |
| `TaskNotCancelableError` | `A2A::TaskNotCancelableError` | ✅ Direct mapping |
| `PushNotificationNotSupportedError` | `A2A::PushNotificationNotSupportedError` | ✅ Direct mapping |
| `UnsupportedOperationError` | `A2A::UnsupportedOperationError` | ✅ Direct mapping |
| `ContentTypeNotSupportedError` | `A2A::ContentTypeNotSupportedError` | ✅ Direct mapping |
| `InvalidAgentResponseError` | `A2A::InvalidAgentResponseError` | ✅ Direct mapping |
| `AuthenticatedExtendedCardNotConfiguredError` | `A2A::AuthenticatedExtendedCardNotConfiguredError` | ✅ Direct mapping |
| `A2AError` | `A2A::Error` | ✅ Direct mapping |

## A2A Request Types

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `SendMessageRequest` | `A2A::SendMessageRequest` | ✅ Direct mapping |
| `SendStreamingMessageRequest` | `A2A::SendStreamingMessageRequest` | ✅ Direct mapping |
| `GetTaskRequest` | `A2A::GetTaskRequest` | ✅ Direct mapping |
| `CancelTaskRequest` | `A2A::CancelTaskRequest` | ✅ Direct mapping |
| `SetTaskPushNotificationConfigRequest` | `A2A::SetTaskPushNotificationConfigRequest` | ✅ Direct mapping |
| `GetTaskPushNotificationConfigRequest` | `A2A::GetTaskPushNotificationConfigRequest` | ✅ Direct mapping |
| `TaskResubscriptionRequest` | `A2A::TaskResubscriptionRequest` | ✅ Direct mapping |
| `ListTaskPushNotificationConfigRequest` | `A2A::ListTaskPushNotificationConfigRequest` | ✅ Direct mapping |
| `DeleteTaskPushNotificationConfigRequest` | `A2A::DeleteTaskPushNotificationConfigRequest` | ✅ Direct mapping |
| `GetAuthenticatedExtendedCardRequest` | `A2A::GetAuthenticatedExtendedCardRequest` | ✅ Direct mapping |
| `A2ARequest` | `A2A::Request` | ✅ Direct mapping |

## A2A Response Types - Consolidated Approach

### TypeScript Pattern: Separate Success/Error Types
```typescript
// TypeScript defines separate interfaces
interface SendMessageSuccessResponse extends JSONRPCSuccessResponse {
  result: Message | Task;
}
type SendMessageResponse = SendMessageSuccessResponse | JSONRPCErrorResponse;
```

### Ruby Pattern: Unified Response Classes
```ruby
# Ruby uses single class with polymorphic behavior
class SendMessageResponse < JSONRPC::Response
  # Handles both success and error cases
  # Use response.success? or response.error? to discriminate
end
```

| TypeScript Success Type | TypeScript Union Type | Ruby Equivalent | Status |
|------------------------|----------------------|-----------------|--------|
| `SendMessageSuccessResponse` | `SendMessageResponse` | `A2A::SendMessageResponse` | 🔄 **Consolidated** |
| `SendStreamingMessageSuccessResponse` | `SendStreamingMessageResponse` | `A2A::SendStreamingMessageResponse` | 🔄 **Consolidated** |
| `GetTaskSuccessResponse` | `GetTaskResponse` | `A2A::GetTaskResponse` | 🔄 **Consolidated** |
| `CancelTaskSuccessResponse` | `CancelTaskResponse` | `A2A::CancelTaskResponse` | 🔄 **Consolidated** |
| `SetTaskPushNotificationConfigSuccessResponse` | `SetTaskPushNotificationConfigResponse` | `A2A::SetTaskPushNotificationConfigResponse` | 🔄 **Consolidated** |
| `GetTaskPushNotificationConfigSuccessResponse` | `GetTaskPushNotificationConfigResponse` | `A2A::GetTaskPushNotificationConfigResponse` | 🔄 **Consolidated** |
| `ListTaskPushNotificationConfigSuccessResponse` | `ListTaskPushNotificationConfigResponse` | `A2A::ListTaskPushNotificationConfigResponse` | 🔄 **Consolidated** |
| `DeleteTaskPushNotificationConfigSuccessResponse` | `DeleteTaskPushNotificationConfigResponse` | `A2A::DeleteTaskPushNotificationConfigResponse` | 🔄 **Consolidated** |
| `GetAuthenticatedExtendedCardSuccessResponse` | `GetAuthenticatedExtendedCardResponse` | `A2A::GetAuthenticatedExtendedCardResponse` | 🔄 **Consolidated** |

## Core Protocol Types

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `AgentCard` | `A2A::AgentCard` | ✅ Direct mapping |
| `AgentProvider` | `A2A::AgentProvider` | ✅ Direct mapping |
| `AgentCapabilities` | `A2A::AgentCapabilities` | ✅ Direct mapping |
| `AgentExtension` | `A2A::AgentExtension` | ✅ Direct mapping |
| `AgentSkill` | `A2A::AgentSkill` | ✅ Direct mapping |
| `AgentInterface` | `A2A::AgentInterface` | ✅ Direct mapping |
| `AgentCardSignature` | `A2A::AgentCardSignature` | ✅ Direct mapping |
| `TransportProtocol` | `A2A::TransportProtocol` | ✅ Direct mapping |
| `Task` | `A2A::Task` | ✅ Direct mapping |
| `TaskStatus` | `A2A::TaskStatus` | ✅ Direct mapping |
| `TaskState` | `A2A::TaskState` | ✅ Direct mapping |
| `TaskStatusUpdateEvent` | `A2A::TaskStatusUpdateEvent` | ✅ Direct mapping |
| `TaskArtifactUpdateEvent` | `A2A::TaskArtifactUpdateEvent` | ✅ Direct mapping |
| `Message` | `A2A::Message` | ✅ Direct mapping |
| `Artifact` | `A2A::Artifact` | ✅ Direct mapping |
| `Part` | `A2A::Part` (union type) | ✅ Direct mapping |
| `TextPart` | `A2A::TextPart` | ✅ Direct mapping |
| `FilePart` | `A2A::FilePart` | ✅ Direct mapping |
| `DataPart` | `A2A::DataPart` | ✅ Direct mapping |
| `PartBase` | `A2A::PartBase` | ✅ Direct mapping |
| `FileBase` | `A2A::FileBase` | ✅ Direct mapping |
| `FileWithBytes` | `A2A::FileWithBytes` | ✅ Direct mapping |
| `FileWithUri` | `A2A::FileWithUri` | ✅ Direct mapping |

## Security Types

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `SecurityScheme` | `A2A::SecurityScheme` (union type) | ✅ Direct mapping |
| `SecuritySchemeBase` | `A2A::SecuritySchemeBase` | ✅ Direct mapping |
| `APIKeySecurityScheme` | `A2A::APIKeySecurityScheme` | ✅ Direct mapping |
| `HTTPAuthSecurityScheme` | `A2A::HTTPAuthSecurityScheme` | ✅ Direct mapping |
| `MutualTLSSecurityScheme` | `A2A::MutualTLSSecurityScheme` | ✅ Direct mapping |
| `OAuth2SecurityScheme` | `A2A::OAuth2SecurityScheme` | ✅ Direct mapping |
| `OpenIdConnectSecurityScheme` | `A2A::OpenIdConnectSecurityScheme` | ✅ Direct mapping |
| `OAuthFlows` | `A2A::OAuthFlows` | ✅ Direct mapping |
| `AuthorizationCodeOAuthFlow` | `A2A::AuthorizationCodeOAuthFlow` | ✅ Direct mapping |
| `ClientCredentialsOAuthFlow` | `A2A::ClientCredentialsOAuthFlow` | ✅ Direct mapping |
| `ImplicitOAuthFlow` | `A2A::ImplicitOAuthFlow` | ✅ Direct mapping |
| `PasswordOAuthFlow` | `A2A::PasswordOAuthFlow` | ✅ Direct mapping |

## Parameter Types

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `TaskIdParams` | `A2A::TaskIdParams` | ✅ Direct mapping |
| `TaskQueryParams` | `A2A::TaskQueryParams` | ✅ Direct mapping |
| `MessageSendParams` | `A2A::MessageSendParams` | ✅ Direct mapping |
| `MessageSendConfiguration` | `A2A::MessageSendConfiguration` | ✅ Direct mapping |
| `GetTaskPushNotificationConfigParams` | `A2A::GetTaskPushNotificationConfigParams` | ✅ Direct mapping |
| `ListTaskPushNotificationConfigParams` | `A2A::ListTaskPushNotificationConfigParams` | ✅ Direct mapping |
| `DeleteTaskPushNotificationConfigParams` | `A2A::DeleteTaskPushNotificationConfigParams` | ✅ Direct mapping |

## Push Notification Types

| TypeScript Type | Ruby Equivalent | Status |
|-----------------|-----------------|--------|
| `PushNotificationConfig` | `A2A::PushNotificationConfig` | ✅ Direct mapping |
| `PushNotificationAuthenticationInfo` | `A2A::PushNotificationAuthenticationInfo` | ✅ Direct mapping |
| `TaskPushNotificationConfig` | `A2A::TaskPushNotificationConfig` | ✅ Direct mapping |

## Usage Examples

### TypeScript Approach
```typescript
// Separate types for success/error
if (response instanceof SendMessageSuccessResponse) {
  // Handle success
  console.log(response.result);
} else if (response instanceof JSONRPCErrorResponse) {
  // Handle error
  console.log(response.error);
}
```

### Ruby Approach
```ruby
# Polymorphic behavior with single class
response = A2A::SendMessageResponse.new(...)

if response.success?
  # Handle success
  puts response.result
else
  # Handle error
  puts response.error
end
```

## Benefits of Ruby Consolidated Approach

1. **🔧 Less Code Duplication**: One response class per method vs. two in TypeScript
2. **📦 Fewer Files**: Easier codebase navigation and maintenance
3. **🏗️ Inheritance Benefits**: Shared functionality via `JSONRPC::Response` base class
4. **🎯 Ruby Idioms**: `success?`/`error?` methods are more idiomatic than type checking
5. **⚡ Same Functionality**: All TypeScript capabilities preserved
6. **🔍 Type Safety**: Maintained via dry-types and optional RBS signatures