require "time"

class Redis
  module Attrs
    class Base

      def initialize(klass, name, type)
        @klass, @name, @type = klass, name, type
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
            redis.set("#{klass.redis_key_prefix}:#{id}:#{name}", value)
          end
        end
      end

      def redis
        Redis::Attrs.redis
      end

      def deserialize(value)
        value
      end

    end

    autoload :String,  'redis-attrs/string'
    autoload :Boolean, 'redis-attrs/boolean'
    autoload :Date,    'redis-attrs/date'
    autoload :Time,    'redis-attrs/time'
    autoload :Integer, 'redis-attrs/integer'
    autoload :Float,   'redis-attrs/float'
  end
end
