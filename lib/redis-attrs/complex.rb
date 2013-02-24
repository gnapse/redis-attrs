require "redis/hash_key"
require "redis/list"
require "redis/set"
require "redis/sorted_set"
require "redis/lock"
require "redis/counter"

class Redis
  module Attrs
    class Complex < Base

      def initialize(klass, name, type)
        super
        attr = self
        attr_class = self.class.redis_object_class[self.type]

        # Define the getter
        klass.send(:define_method, name) do
          instance_variable_get("@#{name}") || begin
            obj = attr_class.new attr.redis_key(id), redis
            instance_variable_set("@#{name}", obj)
          end
        end

        # TODO: Add support for collection setters
      end

      def self.redis_object_class
        @@redis_object_class ||= {
          lock:       Redis::Lock,
          counter:    Redis::Counter,
          hash:       Redis::HashKey,
          list:       Redis::List,
          set:        Redis::Set,
          sorted_set: Redis::SortedSet,
        }
      end

    end
  end
end
