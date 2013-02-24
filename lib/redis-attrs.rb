require "redis-attrs/version"
require "redis"
require "active_support/inflector"

class Redis
  module Attrs
    def self.redis
      @redis ||= Redis.new
    end

    def self.redis=(r)
      raise ArgumentError, "Redis Attrs: Invalid Redis instance" unless r.is_a?(Redis)
      @redis = r
    end

    module ClassMethods
      def redis
        Redis::Attrs.redis
      end

      def redis_key_prefix
        @redis_key_refix ||= ActiveSupport::Inflector.underscore(self.name)
      end

      def redis_attrs(attrs = nil)
        @redis_attrs ||= []
        return @redis_attrs if attrs.nil?
        attrs.each do |name, type|
          klass = Redis::Attrs::supported_types[type]
          raise ArgumentError, "Unknown Redis::Attr type #{type}" if klass.nil?
          attr = klass.new(self, name, type)
          @redis_attrs << attr
        end
      end
    end

    module InstanceMethods
      def redis
        Redis::Attrs.redis
      end
    end

    def self.included(receiver)
      receiver.extend(ClassMethods)
      receiver.send(:include, InstanceMethods)
    end

    def self.supported_types
      @supported_types ||= {
        # Scalar types
        string:  Redis::Attrs::String,
        boolean: Redis::Attrs::Boolean,
        date:    Redis::Attrs::Date,
        time:    Redis::Attrs::Time,
        integer: Redis::Attrs::Integer,
        float:   Redis::Attrs::Float,

        # Complex types
        hash:       Redis::Attrs::Complex,
        list:       Redis::Attrs::Complex,
        set:        Redis::Attrs::Complex,
        sorted_set: Redis::Attrs::Complex,
      }
    end

    def self.register_type(type, klass)
      type = type.to_sym
      raise ArgumentError, "Redis attr type #{type} is already defined" if supported_types.include?(type)
      raise ArgumentError, "Class implementing new type #{type} must be a subclass of Redis::Attrs::Scalar" unless klass.ancestors.include?(Scalar)
      @supported_types[type] = klass
    end

    autoload :Base,    'redis-attrs/base'
    autoload :Scalar,  'redis-attrs/scalar'
    autoload :String,  'redis-attrs/string'
    autoload :Boolean, 'redis-attrs/boolean'
    autoload :Date,    'redis-attrs/date'
    autoload :Time,    'redis-attrs/time'
    autoload :Integer, 'redis-attrs/integer'
    autoload :Float,   'redis-attrs/float'

    autoload :Complex,   'redis-attrs/complex'
  end
end
