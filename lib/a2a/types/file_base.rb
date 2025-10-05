# frozen_string_literal: true

module A2A
  # Defines base properties for a file.
  class FileBase < ProtocolStruct
    # @return [String, nil] An optional name for the file (e.g., "document.pdf").
    attribute? :name, Types::String.optional

    # @return [String, nil] The MIME type of the file (e.g., "application/pdf").
    attribute? :mime_type, Types::String.optional
  end
end
