require "spec_helper"

class Film
  include Redis::Attrs
  redis_attrs title: :string, released_on: :date, length: :integer
  redis_attrs created_at: :time, rating: :float, featured: :boolean

  def id
    1
  end
end

describe Redis::Attrs do
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
    let(:redis) { Redis::Attrs.redis }

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
end
