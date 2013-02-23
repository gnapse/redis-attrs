require "redis-attrs/version"
require "time"
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
          deserializer = deserialize(type)
          if deserializer.nil?
            # TODO: Warning?
            next
          end

          # Define the getter
          define_method(name) do
            value = redis.get("#{self.class.redis_key_prefix}:#{id}:#{name}")
            value.nil? ? nil : deserializer.call(value)
          end

          # Define the setter
          define_method("#{name}=") do |value|
            if value.nil?
              redis.del("#{self.class.redis_key_prefix}:#{id}:#{name}")
            else
              redis.set("#{self.class.redis_key_prefix}:#{id}:#{name}", value)
            end
          end

        end
      end

      private

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
