# Redis::Attrs - Add attributes to Ruby classes backed by Redis

This gem is an amalgamation of the ideas found within the [redis_props][redis_props]
and [redis-objects][redis-objects] gems, plus a few new ideas here and there.  It
provides a way to define, on any Ruby class, some attributes that are backed by
[Redis][redis] behind the curtain.

Here are some of the characteristics that define this library:

- Easy to integrate directly with existing ORMs - ActiveRecord, DataMapper, etc.
- Not confined to ORMs. Use it in whatever Ruby classes you want.
- It does work better with ORMs because it requires each object to provide a
  unique id identifying it, something already provided by most ORMs out of the box.
- Supports scalar value types, as well as more complex value types such as
  collection types, counters and locks.
- Integers are returned as integers, rather than '17'. The same holds for dates,
  times, floats, etc.
- Collection types can be assigned a Ruby-style collection to set their whole
  content at once, resetting whatever content there was in the Redis key.
- The user can add support for more scalar data types with no built-in support.

## Installation

Add this line to your application's Gemfile:

    gem 'redis-attrs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-attrs

## Usage

Start by defining some attributes on your class:

    class Film
      include Redis::Attrs
      redis_attrs :title => :string, :length => :integer
      redis_attrs :released_on => :date, :cast => :list

      # Remember that the objects need an id for this to work
      attr_reader :id
      def initialize(id)
        @id = id
      end

      def presentation_title
        "#{title} (#{released_on.year})"
      end
    end

Then you can use those attributes as you would regularly, but internally they are
reading from and writing to Redis.

    >> film = Film.new(3)
    >> film.title = "Argo"
    >> film.released_on = "2012-10-12"
    >> puts film.presentation_title
    Argo (2012)
    >> puts film.cast.size
    0
    >> film.cast = ["Ben Affleck", "Alan Arkin", "Brian Cranston"]
    >> puts film.cast.size
    3
    >> puts film.cast[-3]
    Ben Affleck

`Redis::Attrs` will work on _any_ class that provides an `id` method that returns
a unique value.  `Redis::Attrs` will automatically create keys that are unique to
each object, in the format:

    class_name:id:attr_name

### Supported types

`Redis::Attrs` supports the following scalar types: `string`, `integer`, `float`,
`boolean`, `date` and `time`. These are automatically serialized and deserialized
when written to and read from Redis.

In addition, the library also supports some collection types and a couple other
non-scalar types: `list`, `hash`, `set`, `sorted_set`, `counter` and `lock`.  These
are all implemented using the [redis-objects][redis-objects] gem, each type handled
by a class that encapsulate all Redis logic around them.

### Defining new scalar types

In addition to the predefined scalar types listed above, the user can define its
own scalar types, by subclassing `Redis::Attrs::Scalar` and defining how to serialize
and deserialize its values.

The following example defines a data-type that stores its values serialized as JSON.
The `serialize` and `deserialize` methods define how this process is done.  After
registering the type with `Redis::Attrs`, a new attribute is added to the class
`Film` defined above.

    class JSONScalar < Redis::Attrs::Scalar
      def serialize(value)
        value.to_json
      end

      def deserialize(value)
        JSON.parse(value)
      end
    end

    Redis::Attrs.register_type(:json, JSONScalar)

    class Film
      redis_attrs :director => :json
    end

After the definitions above, more complex data structures could be stored as a single
scalar value, by being serialized as JSON.

    >> film = Film.new(1)
    >> film.director = { "first_name" => "Ben", "last_name" => "Affleck" }
    >> puts Redis::Attrs.redis.get("film:1:director")
    {"first_name":"Ben","last_name":"Affleck"}

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[redis]: http://redis.io
[redis_props]: http://github.com/obie/redis_props
[redis-objects]: http://github.com/nateware/redis-objects
