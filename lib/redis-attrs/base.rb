class Redis
  module Attrs
    class Base
      attr_reader :klass, :name, :type

      def initialize(klass, name, type)
        @klass, @name, @type = klass, name, type
      end

      def redis
        Redis::Attrs.redis
      end
    end
  end
end