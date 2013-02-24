require "time"

class Redis
  module Attrs
    class Scalar < Base

      def initialize(klass, name, type)
        super
        attr = self

        # Define the getter
        klass.send(:define_method, name) do
          value = redis.get attr.redis_key(id)
          value.nil? ? nil : attr.deserialize(value)
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
