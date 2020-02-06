lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynamoid_advanced_where/version'

Gem::Specification.new do |spec|
  spec.name          = 'dynamoid-advanced-where'
  spec.version       = DynamoidAdvancedWhere::VERSION
  spec.authors       = ['Brian Malinconico']
  spec.email         = ['bmalinconico@terminus.com']

  spec.summary       = 'things'
  spec.description   = 'things'
  # spec.homepage      = "things"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dynamoid', '~> 3'

  spec.add_development_dependency 'bundle-audit'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'fasterer'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'appraisal'
end
