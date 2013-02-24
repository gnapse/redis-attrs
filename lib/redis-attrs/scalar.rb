require "time"

class Redis
  module Attrs
    class Scalar < Base

      def initialize(klass, name, type)
        super
        attr = self

        # Define the getter
        klass.send(:define_method, name) do
          value = redis.get("#{klass.redis_key_prefix}:#{id}:#{name}")
          value.nil? ? nil : attr.deserialize(value)
        end

        # Define the setter
        klass.send(:define_method, "#{name}=") do |value|
          if value.nil?
            redis.del("#{klass.redis_key_prefix}:#{id}:#{name}")
          else
            value = attr.serialize(value)
            redis.set("#{klass.redis_key_prefix}:#{id}:#{name}", value)
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
