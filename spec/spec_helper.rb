require "redis-attrs"

Redis::Attrs.redis = Redis.new(db: 13)

RSpec.configure do |config|

  # Clean up the database
  config.before(:each) do
    Redis::Attrs.redis.flushdb
  end

  # Disallow "should" syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

end
