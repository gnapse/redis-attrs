class Redis
  module Attrs
    class Float < Base
      def deserialize(value)
        value.nil? ? nil : value.to_f
      end
    end
  end
end
