
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lightio/version"

Gem::Specification.new do |spec|
  spec.name          = "lightio"
  spec.version       = LightIO::VERSION
  spec.authors       = ["jjy"]
  spec.email         = ["jjyruby@gmail.com"]

  spec.summary       = %q{LightIO is a light weight, user-transparent asynchronous IO library}
  spec.description   = %q{LightIO's goal is provide simple, transparent and efficient IO operation to ruby world}
  spec.homepage      = "https://github.com/jjyr/lightio"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nio4r"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
