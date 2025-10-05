# Agent2Agent (A2A) Protocol - Feature Roadmap

## 1. Core Transport & Communication

### 1.1 Transport Protocols
- [ ] JSON-RPC 2.0 over HTTP(S) transport support
- [ ] gRPC transport support (Protocol Buffers v3)
- [ ] HTTP+JSON/REST transport support
- [ ] Multi-transport capability with functional equivalence
- [ ] Transport-specific optimizations and extensions
- [ ] Transport selection and fallback logic
- [ ] Method mapping across transports (JSON-RPC, gRPC, REST)

### 1.2 Streaming Capabilities
- [ ] Server-Sent Events (SSE) streaming for JSON-RPC
- [ ] gRPC server streaming RPCs
- [ ] HTTP+JSON/REST streaming with SSE
- [ ] Real-time task status updates via streaming
- [ ] Incremental artifact delivery via streaming
- [ ] Stream reconnection and resubscription
- [ ] Stream termination signaling

### 1.3 Message Format
- [ ] JSON-RPC 2.0 request/response structure
- [ ] Protocol Buffers message serialization
- [ ] RESTful JSON request/response format
- [ ] Standard JSON-RPC error responses
- [ ] Transport-agnostic data structures

## 2. Agent Discovery & Metadata

### 2.1 Agent Card
- [ ] Agent Card JSON document structure
- [ ] Well-known URI location (/.well-known/agent-card.json)
- [ ] Agent identity and description
- [ ] Service endpoint URL declaration
- [ ] Protocol version specification
- [ ] Provider information
- [ ] Documentation URL
- [ ] Agent icon URL
- [ ] Agent Card signatures (JWS)

### 2.2 Capabilities Declaration
- [ ] Streaming capability flag
- [ ] Push notifications capability flag
- [ ] Extension declarations
- [ ] Transport protocol declarations (preferred + additional)
- [ ] Multi-interface support declaration

### 2.3 Skills Definition
- [ ] Skill name and description
- [ ] Skill tags for categorization
- [ ] Example queries for skills
- [ ] Input modalities per skill
- [ ] Output modalities per skill
- [ ] Per-skill security requirements

### 2.4 Extended Agent Cards
- [ ] Authenticated extended Agent Card retrieval
- [ ] `supportsAuthenticatedExtendedCard` flag
- [ ] `agent/getAuthenticatedExtendedCard` RPC method

## 3. Security & Authentication

### 3.1 Transport Security
- [ ] HTTPS/TLS requirement enforcement
- [ ] TLS 1.3+ support with strong cipher suites
- [ ] Server identity verification via TLS certificates
- [ ] Client webhook server TLS verification
- [ ] mTLS (Mutual TLS) security scheme

### 3.2 Authentication Schemes
- [ ] API Key authentication (header, query, cookie)
- [ ] HTTP authentication schemes (Bearer, Basic, etc.)
- [ ] OAuth 2.0 authentication
  - [ ] Authorization Code flow
  - [ ] Client Credentials flow
  - [ ] Implicit flow
  - [ ] Password flow
  - [ ] OAuth 2.0 metadata URL support
- [ ] OpenID Connect authentication
- [ ] JWT bearer token format
- [ ] Security scheme declaration in Agent Card
- [ ] Multiple security requirement combinations (OR of ANDs)

### 3.3 Authorization
- [ ] Server-side authorization implementation
- [ ] Principle of least privilege
- [ ] Granular authorization (skills, actions, data)
- [ ] HTTP 401 Unauthorized responses
- [ ] HTTP 403 Forbidden responses
- [ ] WWW-Authenticate header support

### 3.4 In-Task Authentication
- [ ] `auth-required` task state
- [ ] Secondary credential requests during task execution
- [ ] User authentication prompts in task workflow

## 4. Core RPC Methods

### 4.1 Message Operations
- [ ] `message/send` - Send message and initiate/continue task
- [ ] `message/stream` - Send message with streaming updates
- [ ] Blocking vs non-blocking message send configuration
- [ ] Accepted output modes configuration
- [ ] Task restart prevention for terminal states

### 4.2 Task Operations
- [ ] `tasks/get` - Retrieve task status and results
- [ ] `tasks/list` - List tasks (gRPC/REST only)
- [ ] `tasks/cancel` - Request task cancellation
- [ ] `tasks/resubscribe` - Resume streaming for existing tasks
- [ ] Task ID-based operations
- [ ] History length configuration for task retrieval

### 4.3 Push Notification Configuration
- [ ] `tasks/pushNotificationConfig/set` - Configure push notifications
- [ ] `tasks/pushNotificationConfig/get` - Retrieve configuration
- [ ] `tasks/pushNotificationConfig/list` - List configurations
- [ ] `tasks/pushNotificationConfig/delete` - Delete configuration
- [ ] Webhook URL configuration
- [ ] Push notification authentication setup
- [ ] Push notification token management

## 5. Data Structures & Content Types

### 5.1 Messages
- [ ] Message role (user/agent)
- [ ] Message parts array
- [ ] Message ID generation
- [ ] Task ID association
- [ ] Context ID association
- [ ] Reference task IDs
- [ ] Message metadata
- [ ] Extension URI references

### 5.2 Parts (Content Types)
- [ ] TextPart - Plain text content
- [ ] FilePart - File content
  - [ ] Base64-encoded inline files (bytes)
  - [ ] URI-referenced files
  - [ ] File name and MIME type metadata
- [ ] DataPart - Structured JSON data
- [ ] Part metadata support
- [ ] Inline display flag for parts

### 5.3 Artifacts
- [ ] Artifact ID generation
- [ ] Artifact name and description
- [ ] Artifact parts array
- [ ] Artifact metadata
- [ ] Extension URI references for artifacts
- [ ] Incremental artifact updates
- [ ] Append vs replace artifact semantics

### 5.4 Task Structure
- [ ] Task ID (server-generated UUID)
- [ ] Context ID (server-generated UUID)
- [ ] Task status object
- [ ] Conversation history array
- [ ] Artifacts collection
- [ ] Task metadata
- [ ] Task lifecycle management

## 6. Task Lifecycle & States

### 6.1 Task States
- [ ] `submitted` - Task received, awaiting execution
- [ ] `working` - Agent actively processing task
- [ ] `input-required` - Paused, waiting for user input
- [ ] `completed` - Successfully completed (terminal)
- [ ] `failed` - Failed due to error (terminal)
- [ ] `canceled` - Canceled by user (terminal)
- [ ] `rejected` - Rejected by agent (terminal)
- [ ] `auth-required` - Requires authentication
- [ ] `unknown` - Indeterminate state (terminal)

### 6.2 Status Management
- [ ] Task state tracking
- [ ] Status message (human-readable)
- [ ] Status timestamp (ISO 8601)
- [ ] State transition logic
- [ ] Terminal state handling

### 6.3 Context Management
- [ ] Context ID generation
- [ ] Context-based task grouping
- [ ] Related task associations
- [ ] Context persistence across interactions

## 7. Streaming & Events

### 7.1 Status Update Events
- [ ] TaskStatusUpdateEvent structure
- [ ] Task ID in status updates
- [ ] Context ID in status updates
- [ ] New status object
- [ ] Final event flag
- [ ] Status update metadata

### 7.2 Artifact Update Events
- [ ] TaskArtifactUpdateEvent structure
- [ ] Task ID in artifact updates
- [ ] Context ID in artifact updates
- [ ] Artifact payload
- [ ] Append flag for incremental updates
- [ ] Last chunk flag
- [ ] Final event flag

### 7.3 Message Events
- [ ] Message delivery in streams
- [ ] Message-based streaming responses
- [ ] Final message flag

## 8. Push Notifications

### 8.1 Configuration
- [ ] Webhook URL specification
- [ ] Push notification token
- [ ] Authentication information structure
- [ ] Authentication schemes array
- [ ] Credentials/configuration info
- [ ] Per-task notification configuration

### 8.2 Security
- [ ] Webhook URL validation (SSRF prevention)
- [ ] Domain allowlisting
- [ ] Ownership verification
- [ ] Server-to-webhook authentication
- [ ] JWT-based authentication
- [ ] JWKS endpoint support
- [ ] Timestamp validation
- [ ] Nonce/unique ID for replay prevention
- [ ] Signature verification

### 8.3 Delivery
- [ ] Asynchronous notification delivery
- [ ] Notification payload structure
- [ ] Task ID in notifications
- [ ] State change notifications
- [ ] Long-running task support
- [ ] Disconnected client support

## 9. Error Handling

### 9.1 JSON-RPC Standard Errors
- [ ] `-32700` Parse Error - Invalid JSON
- [ ] `-32600` Invalid Request Error
- [ ] `-32601` Method Not Found Error
- [ ] `-32602` Invalid Params Error
- [ ] `-32603` Internal Error

### 9.2 A2A-Specific Errors
- [ ] `-32001` Task Not Found Error
- [ ] `-32002` Task Not Cancelable Error
- [ ] `-32003` Push Notification Not Supported Error
- [ ] `-32004` Unsupported Operation Error
- [ ] `-32005` Content Type Not Supported Error
- [ ] `-32006` Invalid Agent Response Error

### 9.3 Error Response Structure
- [ ] JSONRPCError object structure
- [ ] Error code field
- [ ] Error message field
- [ ] Optional error data field
- [ ] Transport-specific error mapping
- [ ] HTTP status code mapping for REST

## 10. Enterprise Features

### 10.1 Observability
- [ ] Request tracing support
- [ ] Logging infrastructure
- [ ] Metrics collection
- [ ] Performance monitoring
- [ ] Debug capabilities

### 10.2 Resource Management
- [ ] Rate limiting implementation
- [ ] Concurrency controls
- [ ] Resource limits
- [ ] Abuse protection
- [ ] Overload protection

### 10.3 Data Privacy
- [ ] Privacy regulation compliance
- [ ] Data minimization
- [ ] Sensitive data handling
- [ ] Data retention policies
- [ ] PII protection

### 10.4 Input Validation
- [ ] RPC parameter validation
- [ ] Message content validation
- [ ] Artifact structure validation
- [ ] Injection attack prevention
- [ ] Schema validation

## 11. Extensions

### 11.1 Extension Framework
- [ ] Extension URI specification
- [ ] Extension metadata structure
- [ ] Extension method naming conventions
- [ ] Extension backward compatibility
- [ ] Extension documentation requirements

### 11.2 Extension Types
- [ ] Protocol extensions
- [ ] Custom method extensions
- [ ] Data structure extensions
- [ ] Transport extensions
- [ ] Agent-specific extensions

## 12. Compliance & Testing

### 12.1 Agent Compliance
- [ ] Transport support requirements validation
- [ ] Agent Card exposure requirement
- [ ] Core method implementation (send, get, cancel)
- [ ] Optional method implementation tracking
- [ ] Multi-transport compliance verification
- [ ] Data format compliance validation

### 12.2 Client Compliance
- [ ] Multi-transport capability
- [ ] Agent Card processing
- [ ] Transport selection logic
- [ ] Core method usage
- [ ] Error handling compliance
- [ ] Authentication support

### 12.3 Compliance Testing
- [ ] Transport interoperability tests
- [ ] Method mapping verification
- [ ] Error handling tests
- [ ] Data format validation
- [ ] JSON schema validation against TypeScript definitions

## 13. Developer Experience

### 13.1 SDKs & Libraries
- [ ] Python SDK implementation
- [ ] JavaScript/TypeScript SDK implementation
- [ ] Client library implementations
- [ ] Server library implementations
- [ ] Common utilities and helpers

### 13.2 Documentation
- [ ] Protocol specification documentation
- [ ] API reference documentation
- [ ] Integration guides
- [ ] Best practices guide
- [ ] Tutorial documentation
- [ ] Code examples and samples

### 13.3 Tooling
- [ ] Protocol Buffer code generation
- [ ] JSON schema validation tools
- [ ] Agent Card validation tools
- [ ] Testing frameworks
- [ ] CLI tools

## 14. Sample Implementations

### 14.1 Python Samples
- [ ] LangGraph integration example
- [ ] CrewAI integration example
- [ ] Google ADK integration example
- [ ] Python CLI host example
- [ ] Python orchestrator example

### 14.2 JavaScript/TypeScript Samples
- [ ] Genkit integration example
- [ ] JavaScript CLI host example
- [ ] Express-based server implementation

### 14.3 Demo Applications
- [ ] Web UI demo application
- [ ] Multi-agent orchestration demo
- [ ] Conversation visualization
- [ ] Task and event visualization
- [ ] Agent discovery demonstration

## 15. Advanced Features

### 15.1 Task Management
- [ ] Task state persistence
- [ ] In-memory task storage
- [ ] Task history management
- [ ] Multi-session task support
- [ ] Task cancellation logic
- [ ] Task result caching

### 15.2 File Handling
- [ ] File upload support
- [ ] File download support
- [ ] Base64 encoding/decoding
- [ ] File URI resolution
- [ ] File storage management
- [ ] MIME type handling

### 15.3 Forms & Structured Data
- [ ] Form data in DataPart
- [ ] Form submission handling
- [ ] Structured input/output
- [ ] Schema-based validation
- [ ] JSON-serializable data support

### 15.4 Multi-Agent Coordination
- [ ] Agent-to-agent delegation
- [ ] Task context sharing
- [ ] Reference task IDs
- [ ] Cross-agent collaboration
- [ ] Agent discovery mechanisms

---

**Version**: 0.3.0  
**Last Updated**: Based on protocol specification v0.3.0  
**Total Features**: 250+

This roadmap represents the comprehensive feature set defined in the Agent2Agent (A2A) Protocol specification, organized into logical categories for implementation planning and tracking.