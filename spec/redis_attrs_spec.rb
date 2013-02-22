require "spec_helper"

describe Redis::Attrs do
  it "has a version number" do
    Redis::Attrs::VERSION.should_not be_nil
  end
end
