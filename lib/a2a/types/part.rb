# frozen_string_literal: true

module A2A
  # A discriminated union representing a part of a message or artifact, which can
  # be text, a file, or structured data.
  Part = TextPart | FilePart | DataPart
end
