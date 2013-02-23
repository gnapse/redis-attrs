class Redis
  module Attrs
    class Integer < Base
      def deserialize(value)
        value.nil? ? nil : value.to_i
      end
    end
  end
end
