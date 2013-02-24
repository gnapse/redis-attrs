class Redis
  module Attrs
    class Date < Scalar
      def deserialize(value)
        value.nil? ? nil : ::Date.parse(value)
      end
    end
  end
end
