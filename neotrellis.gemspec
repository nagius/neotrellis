lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "neotrellis/version"

Gem::Specification.new do |spec|
  spec.name          = "neotrellis"
  spec.version       = Neotrellis::VERSION
  spec.authors       = ["Nicolas AGIUS"]
  spec.email         = ["nicolas.agius@lps-it.fr"]

  spec.summary       = %q{TO DO: Write a short summary, because RubyGems requires one.}
  spec.description   = %q{TO DO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/nagius/neotrellis"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "i2c", "~>0.4" 
  spec.add_runtime_dependency "ya_gpio", "~>0.1" 
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'yard', '~> 0.9'
end
