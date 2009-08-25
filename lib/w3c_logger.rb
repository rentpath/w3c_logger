module ActionController
  class Base
    class << self
      def w3c_logger
        @w3c_logger ||= case RAILS_DEFAULT_LOGGER.class.to_s
        when 'SyslogLogger'
          # Syslog is in use, use it to log messages
          RAILS_DEFAULT_LOGGER
        else
          # Regular log files, create a seperate log file
          Logger.new("#{RAILS_ROOT}/log/w3c.log")
        end
        @w3c_logger
      end
    end

    # Place logger reference into instance variable for performance improvement
    def w3c_logger
      @w3c_logger ||= self.class.w3c_logger
    end

    def perform_action_with_new_log
      ms = [Benchmark.ms { perform_action_without_new_log }, 0.01].max
      line = []
      line << Time.now.getgm.strftime("%Y-%m-%d\t%H:%M:%S")   || "-"
      line << request.remote_ip                               || "-"
      line << request.method.to_s.upcase                      || "-"
      line << request.request_uri                             || "-"
      line << response.status.to_s.split(" ").first           || "-"

      # If a controller calls send_file the response body is a proc; 
      # therefore, check if body responds to length before calling
      line << (response.body.respond_to?(:length) && response.body.length) || "-"

      line << sprintf("%d", ms)                               || "-"
      line << request.referrer                                || "-"
      line << quotify(request.user_agent                      || "-")
      line << request.cookies.length                          || "-"
      w3c_logger.info line.join("\t")
    end

    alias_method :perform_action_without_new_log, :perform_action
    alias_method :perform_action, :perform_action_with_new_log

    private :perform_action

    def quotify(field)
      "\"#{field}\""
    end
  end
end
