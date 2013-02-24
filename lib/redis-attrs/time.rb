class Redis
  module Attrs
    class Time < Scalar
      def deserialize(value)
        value.nil? ? nil : ::Time.parse(value)
      end
    end
  end
end
