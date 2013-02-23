require "time"

class Redis
  module Attrs
    class Base

      def initialize(klass, name, type)
        @klass, @name, @type = klass, name, type
        attr = self
        raise ArgumentError, "[Redis Attrs] Invalid type #{type}" if deserializer.nil?

        # Define the getter
        klass.send(:define_method, name) do
          value = redis.get("#{klass.redis_key_prefix}:#{id}:#{name}")
          value.nil? ? nil : attr.deserializer.call(value)
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

      def redis
        Redis::Attrs.redis
      end

      def deserializer
        @deserializer ||= case @type
          when :string  then lambda { |v| v }
          when :boolean then lambda { |v| %w(true yes).include?(v.downcase) }
          when :date    then lambda { |v| Date.parse(v) }
          when :time    then lambda { |v| Time.parse(v) }
          when :integer then lambda { |v| v.to_i }
          when :float   then lambda { |v| v.to_f }
          else nil
        end
      end

    end
  end
end
