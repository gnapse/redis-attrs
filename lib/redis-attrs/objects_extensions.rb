class Redis
  module Attrs

    class FilteredList < Redis::List
      def push(value)
        value = options[:filter].call(value) if options[:filter]
        super
      end

      # Add a member before or after pivot in the list. Redis: LINSERT
      def insert(where, pivot, value)
        if options[:filter]
          value = options[:filter].call(value)
          pivot = options[:filter].call(pivot)
        end
        super
      end

      # Add a member to the start of the list. Redis: LPUSH
      def unshift(value)
        value = options[:filter].call(value) if options[:filter]
        super
      end

      def delete(name, count = 0)
        name = options[:filter].call(name) if options[:filter]
        super
      end
    end

    class FilteredSet < Redis::Set
      def add(value)
        value = options[:filter].call(value) if options[:filter]
        super
      end

      def merge(*values)
        if options[:filter]
          filter = options[:filter]
          values = values.map { |value| filter.call(value) }
        end
        super
      end

      def member?(value)
        value = options[:filter].call(value) if options[:filter]
        super
      end

      def delete(value)
        value = options[:filter].call(value) if options[:filter]
        super
      end
    end

  end
end
