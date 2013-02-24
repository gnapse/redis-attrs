class Redis
  module Attrs
    class Hash < Complex
      def setter(id, hash_object, new_hash)
        redis.del redis_key(id)
        new_hash.each { |key, value| hash_object[key] = value }
      end
    end
  end
end