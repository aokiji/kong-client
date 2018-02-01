# frozen_string_literal: true

require 'kong/error'
require_relative 'resource_configuration_methods'

module Kong
  module Clients
    # base client
    class Base
      def initialize(connection, base_path: nil)
        @connection = connection
        @base_path = base_path
      end

      def self.inherited(base)
        base.include ResourceConfigurationMethods
      end

      def self.resource_path_name
        resource_name.to_s.tr('_', '-')
      end

      def self.resource_class
        name_parts = name.split('::')
        name_parts[1] = 'Resources'
        name_parts[-1] = resource_class_name
        Object.const_get(name_parts.join('::'))
      end

      protected

      attr_reader :connection

      def resources_path
        combined_base_path
      end

      def resource_path(id)
        combined_base_path + '/' + id.to_s
      end

      def combined_base_path
        @combined_base_path ||= begin
          resource_path = self.class.resource_path_name
          if @base_path
            @base_path + '/' + resource_path
          else
            resource_path
          end
        end
      end

      def resource_class
        self.class.resource_class
      end
    end
  end
end
