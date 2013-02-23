class Redis
  module Attrs
    class Date < Base
      def deserialize(value)
        value.nil? ? nil : ::Date.parse(value)
      end
    end
  end
end
