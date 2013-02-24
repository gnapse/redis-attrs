class Redis
  module Attrs
    class List < Complex
      def setter(id, list_object, new_list)
        redis.del redis_key(id)
        new_list.each { |item| list_object << item }
      end
    end
  end
end