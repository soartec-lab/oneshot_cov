module OneshotCov
  module Logger
    class LineByLineLogger
      def initialize(logger)
        @logger = logger
      end

      def post(new_logs)
        new_logs.each do |new_log|
          log_path = new_log.path
          oneshot_lines = new_log.lines[:oneshot_lines]

          oneshot_lines.each do |line|
            @logger.info("#{log_path}: #{line}")
          end
        end
      end
    end
  end
end 