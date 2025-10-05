# frozen_string_literal: true

module A2A
  # Represents a file with its content located at a specific URI.
  class FileWithUri < FileBase
    # @return [URI] A URL pointing to the file's content.
    attribute :uri, Types::URI
  end
end
