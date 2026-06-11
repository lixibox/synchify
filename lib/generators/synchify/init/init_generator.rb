module Synchify
  module Generators
    class InitGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install Synchify engine into your Rails application"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/synchify.rb"
      end

      def create_synchify_dirs
        empty_directory "app/synchify/handlers"
        empty_directory "app/synchify/payloads"
      end

      def mount_engine
        route 'mount Synchify::Engine => "/synchify"'
      end

      def install_migrations
        rake "synchify:install:migrations"
      end

      def show_instructions
        say ""
        say "====================================", :green
        say "  Synchify installed successfully!", :green
        say "====================================", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/initializers/synchify.rb"
        say "     - Set SYNCHIFY_SECRET_KEY in your environment"
        say "     - Register incoming/outgoing event classes"
        say "     - Set authenticate_with lambda for UI auth (runs in controller context)"
        say ""
        say "  2. Run migrations:"
        say "     rails db:migrate", :yellow
        say ""
        say "  3. Visit /synchify/settings to get your Handshake URL + Request Key"
        say ""
      end
    end
  end
end
