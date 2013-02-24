class Redis
  module Attrs
    class Boolean < Scalar
      def deserialize(value)
        value.nil? ? nil : %w(true yes).include?(value.downcase)
      end
    end
  end
end