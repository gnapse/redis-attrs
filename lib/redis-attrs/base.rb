require "time"

class Redis
  module Attrs
    class Base

      def initialize(klass, name, type)
        deserializer = deserialize(type)
        raise ArgumentError, "[Redis Attrs] Invalid type #{type}" if deserializer.nil?

        # Define the getter
        klass.send(:define_method, name) do
          value = redis.get("#{klass.redis_key_prefix}:#{id}:#{name}")
          value.nil? ? nil : deserializer.call(value)
        end

        # Define the setter
        klass.send(:define_method, "#{name}=") do |value|
          if value.nil?
            redis.del("#{klass.redis_key_prefix}:#{id}:#{name}")
          else
            redis.set("#{klass.redis_key_prefix}:#{id}:#{name}", value)
          end
        end
      end

      private

      def redis
        Redis::Attrs.redis
      end

      def deserialize(type)
        case type
          when :string
            @string ||= lambda { |v| v }
          when :boolean
            @boolean ||= lambda { |v| %w(true yes).include?(v.downcase) }
          when :date
            @date ||= lambda { |v| Date.parse(v) }
          when :time
            @time ||= lambda { |v| Time.parse(v) }
          when :integer
            @integer ||= lambda { |v| v.to_i }
          when :float
            @float ||= lambda { |v| v.to_f }
          else
            nil
        end
      end

    end
  end
end
