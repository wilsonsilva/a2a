# frozen_string_literal: true

module A2A
  # Represents a part of a message containing file content.
  class FilePart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('file')

    # @return [FileContent] The file content, provided either inline or via URI.
    attribute :file, Types::Constructor(FileContent)

    # @return [Hash, nil] Optional metadata associated with this file part.
    attribute? :metadata, Types::Hash.optional
  end
end
