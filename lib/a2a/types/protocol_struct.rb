# frozen_string_literal: true

require 'dry-struct'

module A2A
  # Base class for all A2A struct objects
  # @!visibility private
  class ProtocolStruct < Dry::Struct
    include Extensions::CaseTransformation
    include Extensions::JSONDeserialization
  end
end
