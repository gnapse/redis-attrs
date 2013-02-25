require "spec_helper"
require "json"

class Film
  include Redis::Attrs
  redis_attrs title: :string, released_on: :date, length: :integer
  redis_attrs created_at: :time, rating: :float, featured: :boolean

  def id
    1
  end
end

class JSONScalar < Redis::Attrs::Scalar
  def serialize(value)
    value.to_json
  end

  def deserialize(value)
    JSON.parse(value)
  end
end

describe Redis::Attrs do
  let(:redis) { Redis::Attrs.redis }
  let(:film) { Film.new }

  it "has a version number" do
    Redis::Attrs::VERSION.should_not be_nil
  end

  context "when included in a class" do
    it "makes the class respond to .redis_attrs" do
      Film.should respond_to(:redis_attrs)
    end

    it "provides the class and its instances with a .redis interface" do
      Film.should respond_to(:redis)
      film.should respond_to(:redis)

      Film.redis.should be_a(Redis)
      Film.redis.should equal(film.redis)
    end
  end

  describe ".redis_attrs" do
    it "adds getters and setters for the attributes defined" do
      %w(title released_on length created_at rating featured).each do |attr|
        film.should respond_to(attr)
        film.should respond_to("#{attr}=")
      end
    end

    context "with no paremeters" do
      it "returns a list of all Redis attributes defined for the class" do
        Film.redis_attrs.should be_a(Array)
        Film.redis_attrs.count.should == 6
        Film.redis_attrs.map(&:name).should == [:title, :released_on, :length, :created_at, :rating, :featured]
        Film.redis_attrs.map(&:type).should == [:string, :date, :integer, :time, :float, :boolean]
      end
    end
  end

  describe "getters" do
    let(:now) { Time.parse("2013-02-22 22:31:12 -0500") }

    it "return nil by default" do
      film.title.should be_nil
      film.released_on.should be_nil
      film.length.should be_nil
    end

    it "return whatever was last set with the corresponding setter" do
      film.title = "Argo"
      film.title.should == "Argo"
    end

    it "keep the original value type" do
      film.released_on = Date.parse("2012-10-12")
      film.released_on.should == Date.parse("2012-10-12")
      film.created_at = now
      film.created_at.should == now
      film.length = 135
      film.length.should == 135
      film.rating = 8.2
      film.rating.should == 8.2
      film.featured = true
      film.featured.should == true
    end
  end

  describe "setters" do
    it "set the corresponding key in Redis" do
      film.title = "Argo"
      redis.get("film:1:title").should == "Argo"

      film.rating = 8.1
      redis.get("film:1:rating").should == "8.1"
    end

    it "unset the key when being assigned nil" do
      film.rating = 8.1
      redis.keys.should include("film:1:rating")

      film.rating = nil
      redis.keys.should_not include("film:1:rating")
      redis.get("film:1:rating").should be_nil
    end
  end

  describe ".register_type" do
    it "allows to define support for scalar value types not covered by the library" do
      Redis::Attrs.register_type(:json, JSONScalar)
      Film.redis_attrs director: :json
      film.director = { first_name: "Ben", last_name: "Affleck" }
      redis.keys.should include("film:1:director")
      redis.get("film:1:director").should == { first_name: "Ben", last_name: "Affleck" }.to_json
      film.director.should == { "first_name" => "Ben", "last_name" => "Affleck" }
    end
  end

  describe "collection attributes" do
    it "support lists" do
      Film.redis_attrs cast: :list
      film.cast.should be_empty
      film.cast = ["Ben Affleck", "Alan Arkin", "John Goodman", "Ben Affleck"]
      film.cast.size.should == 4
    end

    it "support hashes" do
      Film.redis_attrs crew: :hash
      film.crew.should be_empty
      film.crew = { costume: "John Doe", makeup: "Jane Doe", camera: "James Doe" }
      film.crew.size.should == 3
      film.crew.keys.should == %w(costume makeup camera)
    end

    it "support sets" do
      Film.redis_attrs producers: :set
      film.producers.should be_empty
      film.producers = ["Grant Heslov", "Ben Affleck", "George Clooney", "Ben Affleck"]
      film.producers.size.should == 3
    end

    it "support sorted sets" do
      Film.redis_attrs rankings: :sorted_set
      film.rankings.should be_empty
      film.rankings = { "oscars" => 3, "golden globe" => 1, "bafta" => 2 }
      film.rankings.first.should == "golden globe"
      film.rankings.last.should == "oscars"
      film.rankings.members.should == ["golden globe", "bafta", "oscars"]
    end

    it "support counters" do
      Film.redis_attrs awards_count: :counter
      film.awards_count.value.should == 0
      film.awards_count.incr
      film.awards_count.value.should == 1
    end

    it "support locks" do
      Film.redis_attrs playing: :lock
      film.playing.lock {  }
    end

    it "support specifying configuration options" do
      require "active_support/core_ext/numeric/time"
      Film.redis_attr :watching, :lock, :expiration => 3.hours
      film.watching.options[:expiration].should == 3.hours
    end
  end
end
