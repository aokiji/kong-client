# frozen_string_literal: true

module Kong
  module Clients
    # add methods to handle plural resources
    module ResourcesRequestMethods
      def create(attributes = {})
        object = resource_class.new(attributes)
        yield(object) if block_given?
        resource_class.new(connection.create(resources_path, object.to_hash))
      end

      def update(consumer, attributes = {})
        resource_class.new(connection.update(resource_path(consumer.id), attributes))
      end

      def delete(consumer)
        connection.delete resource_path(consumer.id)
      end

      def all(options = {})
        objects = connection.get resources_path, options
        objects['data'].map { |data| resource_class.new(data) }
      end

      def find(id)
        data = connection.get resource_path(id)
        resource_class.new(data)
      end

      def find_by(options)
        all(options).first
      end

      def find_by!(options)
        all(options).first || raise(Kong::Error.new(404, 'Resource not found'))
      end

      def find_or_create_by(attributes, &block)
        find_by(attributes) || create(attributes, &block)
      end
    end
  end
end
