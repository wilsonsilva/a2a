# frozen_string_literal: true

require 'json'

module A2A
  module Extensions
    # A module for copying attributes of a struct
    module Copying
      # @!visibility private
      def copy(new_attributes)
        self.class.new(attributes.merge(new_attributes))
      end
    end
  end
end
