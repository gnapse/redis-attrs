class Redis
  module Attrs
    class Time < Base
      def deserialize(value)
        value.nil? ? nil : ::Time.parse(value)
      end
    end
  end
end
