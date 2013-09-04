class Redis
  module Attrs
    class RaTime < Scalar
      def deserialize(value)
        value.nil? ? nil : ::Time.parse(value)
      end
    end
  end
end
