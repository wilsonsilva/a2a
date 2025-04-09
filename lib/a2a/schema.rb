# frozen_string_literal: true

require_relative 'schema/schema_object'
require_relative 'schema/part'
require_relative 'schema/text_part'
require_relative 'schema/file_part'
require_relative 'schema/data_part'
require_relative 'schema/message'
require_relative 'schema/artifact'
require_relative 'schema/task_state'
require_relative 'schema/task_status'
require_relative 'schema/task'
require_relative 'schema/task_and_history'
require_relative 'schema/task_status_update_event'
require_relative 'schema/task_artifact_update_event'
require_relative 'schema/push_notification_config'
require_relative 'schema/task_push_notification_config'
require_relative 'schema/agent_capabilities'
require_relative 'schema/agent_provider'
require_relative 'schema/agent_authentication'
require_relative 'schema/agent_skill'
require_relative 'schema/agent_card'
require_relative 'schema/task_send_params'
require_relative 'schema/task_id_params'
require_relative 'schema/task_query_params'
require_relative 'schema/jsonrpc_message'
require_relative 'schema/jsonrpc_request'
require_relative 'schema/jsonrpc_error'
require_relative 'schema/jsonrpc_response'
require_relative 'schema/helpers'

module A2A
  module Schema
    # The schema module provides classes for all data structures used in the A2A protocol
  end
end