module Synchify
  class Engine < ::Rails::Engine
    isolate_namespace Synchify

    config.before_initialize do
      Rails.autoloaders.each do |autoloader|
        # Zeitwerk defaults "api_controller" → "Api::Controller"; override to keep it as "ApiController"
        autoloader.inflector.inflect(
          "api_controller"      => "ApiController",
          "open_api_controller" => "OpenApiController",
          "open_api_builder"    => "OpenApiBuilder"
        )
      end
    end

    initializer "synchify.autoload_host_paths", before: :bootstrap_hook do |app|
      dir = Rails.root&.join("app", "synchify")
      next unless dir&.exist?

      app.config.autoload_paths  << dir.to_s unless app.config.autoload_paths.frozen?
      app.config.eager_load_paths << dir.to_s unless app.config.eager_load_paths.frozen?
    end

    config.to_prepare do
      dir = Rails.root&.join("app", "synchify")
      next unless dir&.exist?

      Rails.autoloaders.main.eager_load_dir(dir.to_s)
    end

    initializer "synchify.validate_configuration" do
      next if defined?(Rake)
      next if defined?(Rails::Generators)
      next if ARGV.any? { |a| %w[synchify:init].include?(a) }

      config = Synchify.configuration
      %i[app_name app_code secret_key].each do |key|
        raise ArgumentError, "Synchify: #{key} must be configured" if config.public_send(key).blank?
      end
    end
  end
end
