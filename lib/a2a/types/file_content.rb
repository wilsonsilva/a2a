# frozen_string_literal: true

module A2A
  # Represents the content of a file, either as base64 encoded bytes or a URI.
  class FileContent < ProtocolStruct
    # @return [String, nil] Optional name of the file.
    attribute? :name, Types::String.optional

    # @return [String, nil] Optional MIME type of the file content.
    attribute? :mime_type, Types::String.optional

    # @return [String, nil] File content encoded as a Base64 string. Use this OR `uri`.
    attribute? :bytes, Types::String.optional

    # @return [String, nil] URI pointing to the file content. Use this OR `bytes`.
    attribute? :uri, Types::String.optional
  end
end
