require "redis-attrs/version"
require "redis-attrs/base"
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

      def redis_attrs(attrs)
        attrs.each do |name, type|
          Redis::Attrs::Base.new(self, name, type)
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
  end
end
