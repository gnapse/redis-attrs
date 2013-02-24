class Redis
  module Attrs
    class Float < Scalar
      def deserialize(value)
        value.nil? ? nil : value.to_f
      end
    end
  end
end
