module OneshotCov
  module Logger
    class EachFileLogger
      def initialize(logger)
        @logger = logger
      end
 
      def post(new_logs)
        new_logs.each do |new_log|
          log_path = new_log.path
          lines = new_log.lines.join(",")

          @logger.info("#{log_path}: #{lines}")
        end
      end
    end
  end
end 