class Redis
  module Attrs
    class Boolean < Base
      def deserialize(value)
        value.nil? ? nil : %w(true yes).include?(value.downcase)
      end
    end
  end
end