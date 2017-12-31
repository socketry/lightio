
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lightio/version"

Gem::Specification.new do |spec|
  spec.name          = "lightio"
  spec.version       = LightIO::VERSION
  spec.authors       = ["Jiang Jinyang"]
  spec.email         = ["jjyruby@gmail.com"]

  spec.summary       = %q{LightIO is a ruby networking library, that combines ruby fiber and fast IO event loop.}
  spec.description   = %q{The intent of LightIO is to provide ruby stdlib compatible modules, that user can use these modules instead stdlib, to gain the benefits of IO event loop without care any details about react or async programming.}
  spec.homepage      = "https://github.com/jjyr/lightio"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nio4r", "~> 2.2"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
