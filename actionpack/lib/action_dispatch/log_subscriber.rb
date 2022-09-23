# frozen_string_literal: true

# :markup: markdown

module ActionDispatch
  class LogSubscriber < ActiveSupport::LogSubscriber
    class_attribute :backtrace_cleaner, default: ActiveSupport::BacktraceCleaner.new

    def redirect(event)
      payload = event.payload

      info { "Redirected to #{payload[:location]}" }
      if ActionDispatch.verbose_redirect_logs
        log_redirect_source(payload[:source])
      end

      info do
        status = payload[:status]

        message = +"Completed #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]} in #{event.duration.round}ms"
        message << "\n\n" if defined?(Rails.env) && Rails.env.development?

        message
      end
    end
    subscribe_log_level :redirect, :info

    private
      def log_redirect_source(backtrace)
        source = extract_query_source_location(backtrace)

        if source
          info  { "↳ #{source}" }
        end
      end

      def extract_query_source_location(locations)
        backtrace_cleaner.clean(locations.lazy).first
      end
  end
end

ActionDispatch::LogSubscriber.attach_to :action_dispatch
