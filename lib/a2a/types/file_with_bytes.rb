# frozen_string_literal: true

module A2A
  # Represents a file with its content provided directly as a base64-encoded string.
  class FileWithBytes < FileBase
    # @return [String] The base64-encoded content of the file.
    attribute :bytes, Types::String
  end
end
