# frozen_string_literal: true

module A2A
  # An event sent by the agent to notify the client that an artifact has been
  # generated or updated. This is typically used in streaming models.
  class TaskArtifactUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task this artifact belongs to.
    attribute :task_id, Types::String

    # @return [String] The context ID associated with the task.
    attribute :context_id, Types::String

    # @return [String] The type of this event, used as a discriminator. Always 'artifact-update'.
    attribute :kind, Types::String.constant('artifact-update')

    # @return [Artifact] The artifact that was generated or updated.
    attribute :artifact, Types::Constructor(Artifact)

    # @return [Boolean, nil] If true, the content of this artifact should be appended to a previously sent artifact
    #   with the same ID.
    attribute? :append, Types::Bool.optional

    # @return [Boolean, nil] If true, this is the final chunk of the artifact.
    attribute? :last_chunk, Types::Bool.optional

    # @return [Hash, nil] Optional metadata for extensions.
    attribute? :metadata, Types::Hash.optional
  end
end
