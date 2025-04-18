# frozen_string_literal: true

module A2A
  # Represents a single part of a multi-part message. Can be text, file, or data.
  Part = TextPart | FilePart | DataPart
end
