require "redis/hash_key"
require "redis/list"
require "redis/set"
require "redis/sorted_set"

class Redis
  module Attrs
    class Complex < Base

      def initialize(klass, name, type)
        super
        attr = self
        attr_class = self.class.redis_object_class[self.type]

        # Define the getter
        klass.send(:define_method, name) do
          @object ||= attr_class.new attr.redis_key(id), redis
        end

        # TODO: Add support for collection setters
      end

      def self.redis_object_class
        @@redis_object_class ||= {
          hash:       Redis::HashKey,
          list:       Redis::List,
          set:        Redis::Set,
          sorted_set: Redis::SortedSet,
        }
      end

    end
  end
end
