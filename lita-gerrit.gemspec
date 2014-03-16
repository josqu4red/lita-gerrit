Gem::Specification.new do |spec|
  spec.name          = "lita-gerrit"
  spec.version       = "0.0.1"
  spec.authors       = ["Jonathan Amiez"]
  spec.email         = ["jonathan.amiez@gmail.com"]
  spec.description   = "Gerrit API client and hook events handler"
  spec.summary       = "Retrieve change status from chat and display events"
  spec.homepage      = "https://github.com/josqu4red/lita-gerrit"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", "~> 3.0"
  spec.add_runtime_dependency "httparty", "~> 0.13.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 0"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta2"
end
