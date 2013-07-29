# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis-attrs/version'

Gem::Specification.new do |gem|
  gem.name          = "redis-attrs"
  gem.version       = Redis::Attrs::VERSION
  gem.authors       = ["Ernesto Garcia"]
  gem.email         = ["gnapse@gmail.com"]
  gem.description   = %q{A module that allows Ruby objects to define attributes backed by a Redis data store. Works with any class or ORM.}
  gem.summary       = %q{Add persistent object attributes backed by redis}
  gem.homepage      = "http://github.com/gnapse/redis-attrs"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec"
  gem.add_dependency "redis"
  gem.add_dependency "activesupport"
  gem.add_dependency "redis-objects"
end
