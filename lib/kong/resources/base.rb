# frozen_string_literal: true

module Kong
  module Resources
    # consumer resource
    class Base
      def initialize(attrs)
        self.attributes = attrs
      end

      def attributes=(attrs)
        attrs.each do |attr, value|
          setter = "#{attr}="
          public_send(setter, value)
        end
      end

      def to_hash
        instance_variables.each_with_object({}) do |var, hash|
          key = var[1..-1]
          hash[key] = instance_variable_get(var)
        end
      end

      def ==(other)
        other.is_a?(self.class) && to_hash == other.to_hash
      end
    end
  end
end
