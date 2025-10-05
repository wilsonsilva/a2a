# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.1.1/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-10-05

### Added

- Type compatibility with version 0.3.0 of the Agent2Agent specification
- Security scheme types:
  - `ApiKeySecurityScheme`
  - `HttpAuthSecurityScheme`
  - `OAuth2SecurityScheme` with OAuth flow types (authorization code, client credentials, implicit, password)
  - `MutualTlsSecurityScheme`
  - `OpenIdConnectSecurityScheme`
- Agent discovery types:
  - `AgentCardSignature` for signed agent cards
  - `AgentExtension` for protocol extensions
  - `AgentInterface` for defining agent interfaces
  - `TransportProtocol` enumeration
- File types:
  - `FileBase` base class
  - `FileWithBytes` for inline file content
  - `FileWithURI` for file references
- Message and task types:
  - `MessageSendConfiguration` and `MessageSendParams`
  - `SendMessageRequest` and `SendMessageResponse`
  - `SendStreamingMessageRequest` and `SendStreamingMessageResponse`
- Push notification configuration endpoints:
  - `GetTaskPushNotificationConfigRequest` and `GetTaskPushNotificationConfigResponse`
  - `SetTaskPushNotificationConfigRequest`
  - `DeleteTaskPushNotificationConfigRequest` and `DeleteTaskPushNotificationConfigResponse`
  - `ListTaskPushNotificationConfigRequest` and `ListTaskPushNotificationConfigResponse`
  - `PushNotificationAuthenticationInfo`
- Error types:
  - `ContentTypeNotSupportedError`
  - `InvalidAgentResponseError`
  - `AuthenticatedExtendedCardNotConfiguredError`
- Claude Code development command for Gemfile updates (`.claude/commands/gemfile/update.md`)

### Changed

- Refactored URL attributes to use `Types::URI` for type safety
- Switched to `MultiJson` for JSON deserialization
- Migrated to `jsonrpc-middleware` gem for JSON-RPC protocol implementation
- Updated `AgentCard` structure with new authentication and extension fields
- Updated `Message` type with new structure and support for artifacts
- Updated `Task` type with new structure
- Refactored `Artifact`, `TaskArtifactUpdateEvent`, and `TaskStatusUpdateEvent` types
- Refactored agent and message types for specification compliance
- Updated error types to use structured error responses

### Removed

- `TaskSendParams` (replaced by `MessageSendParams`)
- `SendTaskRequest` and `SendTaskResponse` (replaced by message send endpoints)
- `SendTaskStreamingRequest` and `SendTaskStreamingResponse` (replaced by streaming message endpoints)
- Legacy JSON-RPC types (now provided by `jsonrpc-middleware`):
  - `JsonrpcMessage`
  - `JsonrpcRequest`
  - `JsonrpcResponse`
  - `JsonrpcError`
  - `InternalError`
  - `InvalidParamsError`
  - `InvalidRequestError`
  - `JsonParseError`
  - `MethodNotFoundError`
- `AgentAuthentication` and `AuthenticationInfo` (replaced by security schemes)
- `FileContent` (replaced by file type hierarchy)

## [0.1.0] - 2025-05-03

### Added

- Protocol data structures defined according to the Agent2Agent specification
- Serialization and deserialization of protocol messages
- Typed data structures with validation
- Case transformation support (snake_case ↔ camelCase) during instantiation and serialization
- Flexible schema with support for additional properties beyond defined attributes

## [0.1.0.pre] - 2025-04-08

- Pre-release

[0.2.0]: https://github.com/wilsonsilva/a2a/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wilsonsilva/a2a/compare/v0.1.0.pre...v0.1.0
[0.1.0.pre]: https://github.com/wilsonsilva/a2a/compare/a20b9b6...v0.1.0.pre
