# frozen_string_literal: true

require "rails/command"

module Rails
  module Command
    class RoutesCommand < Base # :nodoc:
      CACHE_FILE_NAME = "tmp/cache/routes"
      ROUTE_GLOB = [
        "config/routes.rb",
        "config/routes/*.rb",
        "engines/*/config/routes.rb",
        "engines/*/config/routes/*.rb",
      ].freeze

      class_option :controller, aliases: "-c", desc: "Filter by a specific controller, e.g. PostsController or Admin::PostsController."
      class_option :grep, aliases: "-g", desc: "Grep routes by a specific pattern."
      class_option :expanded, type: :boolean, aliases: "-E", desc: "Print routes expanded vertically with parts explained."
      class_option :unused, type: :boolean, aliases: "-u", desc: "Print unused routes."

      no_commands do
        def invoke_command(*)
          if options.key?("unused")
            Rails::Command.invoke "unused_routes", ARGV
          else
            super
          end
        end
      end

      desc "routes", "List all the defined routes"
      def perform(*)
        say cached_formatted_routes
      end

      private
        def cache_key
          keys = Dir.glob(ROUTE_GLOB).map do |file|
            "#{file}:#{File.mtime(file)}"
          end

          ActiveSupport::Cache.expand_cache_key(keys)
        end

        # Can't cache routes if options are provided, as we cannot marshal the
        # routes themselves before they are filtered, as it's a very complex object.
        def cacheable?
          options.empty?
        end

        def cache
          ActiveSupport::Cache::FileStore.new(CACHE_FILE_NAME)
        end

        def formatted_routes
          boot_application!
          require "action_dispatch/routing/inspector"

          inspector.format(formatter, routes_filter)
        end

        def cached_formatted_routes
          return formatted_routes unless cacheable?

          cache.fetch(cache_key) do
            cache.clear
            formatted_routes
          end
        end

        def inspector
          ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes)
        end

        def formatter
          if options.key?("expanded")
            ActionDispatch::Routing::ConsoleFormatter::Expanded.new
          else
            ActionDispatch::Routing::ConsoleFormatter::Sheet.new
          end
        end

        def routes_filter
          options.symbolize_keys.slice(:controller, :grep)
        end
    end
  end
end
