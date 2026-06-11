require_relative "lib/synchify/version"

Gem::Specification.new do |spec|
  spec.name        = "synchify"
  spec.version     = Synchify::VERSION
  spec.authors     = [ "Khoa Nguyen" ]
  spec.email       = [ "khoa@lixibox.com" ]
  spec.summary     = "Rails Engine for managing bi-directional integrations and webhooks between apps."
  spec.license     = "MIT"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0.6.1"
  spec.add_dependency "haml-rails"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pg"
end
