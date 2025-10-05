# frozen_string_literal: true

module A2A
  # Represents a file segment within a message or artifact. The file content can be
  # provided either directly as bytes or as a URI.
  class FilePart < PartBase
    # @return [String] The type of this part, used as a discriminator. Always 'file'.
    attribute :kind, Types::String.constant('file')

    # @return [FileWithBytes | FileWithUri] The file content, represented as either a URI or as base64-encoded bytes.
    attribute :file, Types::Constructor(FileWithBytes | FileWithUri)
  end
end
