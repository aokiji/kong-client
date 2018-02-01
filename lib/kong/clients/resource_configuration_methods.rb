# frozen_string_literal: true

require_relative 'resources_request_methods'

module Kong
  module Clients
    # allow client to define either resource or resources
    module ResourceConfigurationMethods
      def self.included(base)
        class <<base
          attr_accessor :resource_name
          attr_writer :resource_class_name
        end
        base.extend ClassMethods
      end

      # class methods
      module ClassMethods
        def resources(type, class_name: nil)
          include ResourcesRequestMethods
          self.resource_name = type
          self.resource_class_name = class_name if class_name
        end

        def resource_class_name
          @resource_class_name ||=
            resource_name.to_s.sub(/s$/, '').split('_').collect(&:capitalize).join
        end
      end
    end
  end
end
