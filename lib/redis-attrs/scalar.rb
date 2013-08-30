require "time"

class Redis
  module Attrs
    class Scalar < Base

      def initialize(klass, name, type, options)
        super
        attr = self

        # Define the getter
        klass.send(:define_method, name) do
          value = redis.get attr.redis_key(id)
          if value.nil?
            attr.options && attr.options[:default] ? attr.options[:default] : nil
          else
             attr.deserialize(value)
          end
        end

        # Define the setter
        klass.send(:define_method, "#{name}=") do |value|
          if value.nil?
            redis.del attr.redis_key(id)
          else
            value = attr.serialize(value)
            redis.set attr.redis_key(id), value
          end
        end
      end

      def serialize(value)
        value.to_s
      end

      def deserialize(value)
        value
      end

    end
  end
end
