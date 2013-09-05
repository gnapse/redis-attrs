require "redis-attrs/version"
require "redis"
require "active_support/inflector"

class Redis
  module Attrs
    def self.redis
      @redis || $redis || Redis.current ||
        raise(NotConnected, "Redis::Attrs.redis not set to a valid redis connection")
    end

    def self.redis=(r)
      @redis = r
    end

    module ClassMethods
      def redis
        Redis::Attrs.redis
      end

      def redis_key_prefix
        @redis_key_refix ||= ActiveSupport::Inflector.underscore(name)
      end

      def redis_attrs(attrs = nil)
        @redis_attrs ||= []
        return @redis_attrs if attrs.nil?
        attrs.each do |name, type|
          redis_attr name, type
        end
      end

      def redis_attr(name, type, options = {})
        @redis_attrs ||= []
        klass = Redis::Attrs.supported_types[type]
        raise ArgumentError, "Unknown Redis::Attr type #{type}" if klass.nil?
        attr = klass.new(self, name, type, options)
        @redis_attrs << attr
      end
    end

    module InstanceMethods
      def redis
        Redis::Attrs.redis
      end

      def redis_key
        redis_key_prefix+":#{id}"
      end

      def redis_attrs_init_all_scalar
        redis.pipelined do
          self.class.redis_attrs.each do |ra|
            if ra.is_a?(Scalar) && ra.options[:default]
              redis.set(ra.redis_key(id), ra.options[:default])
            else
              redis.del ra.redis_key(id)
            end
          end
        end
      end

      def redis_attrs_get_all_scalar
        redis_ary = redis.pipelined do
          self.class.redis_attrs.each {|ra| redis.get ra.redis_key(id) if ra.is_a?(Scalar) }
        end

        res_hash = {}
        self.class.redis_attrs.each_with_index do |ra, i|
          if redis_ary[i].nil?
            res_hash[ra.name] = ra.options[:default] if ra.options[:default]
          else
            res_hash[ra.name] = ra.deserialize(redis_ary[i])
          end
        end
        res_hash
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
        time:    Redis::Attrs::RaTime,
        integer: Redis::Attrs::Integer,
        float:   Redis::Attrs::Float,

        # Complex types
        counter:    Redis::Attrs::Complex,
        lock:       Redis::Attrs::Complex,
        hash:       Redis::Attrs::Hash,
        list:       Redis::Attrs::List,
        set:        Redis::Attrs::List,
        sorted_set: Redis::Attrs::Hash,
      }
    end

    def self.register_type(type, klass)
      type = type.to_sym
      raise ArgumentError, "Redis attr type #{type} is already defined" if supported_types.include?(type)
      unless klass.ancestors.include?(Scalar)
        raise ArgumentError, "Class implementing new type #{type} must be a subclass of Redis::Attrs::Scalar"
      end
      @supported_types[type] = klass
    end

    autoload :Base,    'redis-attrs/base'
    autoload :Scalar,  'redis-attrs/scalar'
    autoload :String,  'redis-attrs/string'
    autoload :Boolean, 'redis-attrs/boolean'
    autoload :Date,    'redis-attrs/date'
    autoload :RaTime,    'redis-attrs/ra_time'
    autoload :Integer, 'redis-attrs/integer'
    autoload :Float,   'redis-attrs/float'
    autoload :Complex, 'redis-attrs/complex'
    autoload :List,    'redis-attrs/list'
    autoload :Hash,    'redis-attrs/hash'
  end
end
