require "spec_helper"
require "json"

class Film
  include Redis::Attrs
  redis_attrs title: :string, released_on: :date, length: :integer
  redis_attrs created_at: :time, featured: :boolean, rating: :float
  redis_attr(:stars, :integer, {default: 0})
  redis_attr(:scenes, :float, {default: 0.0})

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
    expect(Redis::Attrs::VERSION).not_to be_nil
  end

  context "when included in a class" do
    it "makes the class respond to .redis_attrs" do
      expect(Film).to respond_to(:redis_attrs)
    end

    it "provides the class and its instances with a .redis interface" do
      expect(Film).to respond_to(:redis)
      expect(film).to respond_to(:redis)

      expect(Film.redis).to be_a(Redis)
      expect(Film.redis).to equal(film.redis)
    end

    it "gives instances of the class unique redis keys" do
      expect(film.redis_key).to eq("film:1")
    end

  end

  describe ".redis_attrs" do
    it "adds getters and setters for the attributes defined" do
      %w(title released_on length created_at rating featured).each do |attr|
        expect(film).to respond_to(attr)
        expect(film).to respond_to("#{attr}=")
      end
    end

    context "with no parameters" do
      let(:attrs) { [:title, :released_on, :length, :created_at, :featured, :rating, :stars, :scenes]}
      let(:types) { [:string, :date, :integer, :time, :boolean, :float, :integer, :float] }

      it "returns a list of all Redis attributes defined for the class" do
        expect(Film.redis_attrs).to be_a(Array)
        expect(Film.redis_attrs.count).to eq(8)
        expect(Film.redis_attrs.map(&:name)).to eq(attrs)
        expect(Film.redis_attrs.map(&:type)).to eq(types)
      end
    end
  end

  describe "getters" do
    let(:now) { Time.parse("2013-02-22 22:31:12 -0500") }

    it "returns nil by default" do
      expect(film.title).to be_nil
      expect(film.released_on).to be_nil
      expect(film.length).to be_nil
    end

    it "returns the default value if one is set in options" do
      expect(film.stars).to eq(0)
      expect(film.scenes).to eq(0.0)
    end

    it "returns whatever was last set with the corresponding setter" do
      film.title = "Argo"
      expect(film.title).to eq("Argo")
    end

    it "keeps the original value type" do
      film.released_on = Date.parse("2012-10-12")
      expect(film.released_on).to eq(Date.parse("2012-10-12"))
      film.created_at = now
      expect(film.created_at).to eq(now)
      film.length = 135
      expect(film.length).to eq(135)
      film.rating = 8.2
      expect(film.rating).to eq(8.2)
      film.featured = true
      expect(film.featured).to eq(true)
    end

    it "pipelines and returns all attr values in a hash" do
      film.title = "Argo"
      Film.redis_attrs rankings: :sorted_set
      film.rankings = { "oscars" => 3, "golden globe" => 1, "bafta" => 2 }
      film.length = 135
      film.rating = 8.2
      film.featured = true
      res = film.redis_attrs_get_all_scalar
      expect(res).to eq({:title=>"Argo", :length=>135, :featured=>true, :rating=>8.2, :stars=>0, :scenes=>0.0})
    end
  end

  describe "setters" do
    it "sets the corresponding key in Redis" do
      film.title = "Argo"
      expect(redis.get("film:1:title")).to eq("Argo")

      film.rating = 8.1
      expect(redis.get("film:1:rating")).to eq("8.1")
    end

    it "unsets the key when being assigned nil" do
      film.rating = 8.1
      expect(redis.keys).to include("film:1:rating")

      film.rating = nil
      expect(redis.keys).not_to include("film:1:rating")
      expect(redis.get("film:1:rating")).to be_nil
    end

    it "should set the default values in one pipelined call." do
      film.redis_attrs_init_all_scalar
      expect(film.title).to be_nil
      expect(film.rating).to be_nil
      expect(film.stars).to eq(0)
      expect(film.scenes).to eq(0.0)
    end
  end

  describe ".register_type" do
    let(:director) { { first_name: "Ben", last_name: "Affleck" } }

    it "allows to define support for scalar value types not covered by the library" do
      Redis::Attrs.register_type(:json, JSONScalar)
      Film.redis_attrs director: :json
      film.director = director
      expect(redis.keys).to include("film:1:director")
      expect(redis.get("film:1:director")).to eq(director.to_json)
      expect(film.director).to eq({ "first_name" => "Ben", "last_name" => "Affleck" })
    end
  end

  describe "collection attributes" do
    it "supports lists" do
      Film.redis_attrs cast: :list
      expect(film.cast).to be_empty
      film.cast = ["Ben Affleck", "Alan Arkin", "John Goodman", "Ben Affleck"]
      expect(film.cast.size).to eq(4)
    end

    it "supports hashes" do
      Film.redis_attrs crew: :hash
      expect(film.crew).to be_empty
      film.crew = { costume: "John Doe", makeup: "Jane Doe", camera: "James Doe" }
      expect(film.crew.size).to eq(3)
      expect(film.crew.keys).to eq(%w(costume makeup camera))
    end

    it "supports sets" do
      Film.redis_attrs producers: :set
      expect(film.producers).to be_empty
      film.producers = ["Grant Heslov", "Ben Affleck", "George Clooney", "Ben Affleck"]
      expect(film.producers.size).to eq(3)
    end

    it "supports sorted sets" do
      Film.redis_attrs rankings: :sorted_set
      expect(film.rankings).to be_empty
      film.rankings = { "oscars" => 3, "golden globe" => 1, "bafta" => 2 }
      expect(film.rankings.first).to eq("golden globe")
      expect(film.rankings.last).to eq("oscars")
      expect(film.rankings.members).to eq(["golden globe", "bafta", "oscars"])
    end

    it "supports counters" do
      Film.redis_attrs awards_count: :counter
      expect(film.awards_count.value).to eq(0)
      film.awards_count.incr
      expect(film.awards_count.value).to eq(1)
    end

    it "supports locks" do
      Film.redis_attrs playing: :lock
      film.playing.lock {  }
    end

    it "supports specifying configuration options" do
      require "active_support/core_ext/numeric/time"
      Film.redis_attr :watching, :lock, expiration: 3.hours
      expect(film.watching.options[:expiration]).to eq(3.hours)
    end

    it "supports filtering the values inserted into a list or set" do
      Film.redis_attr :genres, :set, filter: ->(genre) { genre.strip.downcase.gsub(/\s+/, ' ') }
      film.genres = ["Action ", "  drama", "film   Noir", "Drama", "Film noir "]
      expect(film.genres.members.sort).to eq(["action", "drama", "film noir"])
      film.genres << " ACTION  " << "Western"
      expect(film.genres).not_to include("Western")
      expect(film.genres).to include("western")
      expect(film.genres.members.sort).to eq(["action", "drama", "film noir", "western"])
    end
  end

  describe "bugs" do
    it "should not interfere with the ruby Time class" do
      class Film
        def year_test
          Time.now.year
        end
      end

      expect(film.year_test).to eq(Time.now.year)
    end
  end


end
