require "coverage"

require "oneshot_cov/logger/line_by_line_logger"
require "oneshot_cov/logger/replace_logger" 
require "oneshot_cov/middleware"
require "oneshot_cov/reporter"
require "oneshot_cov/railtie" if defined?(Rails)

module OneshotCov
  module_function

  def start
    Coverage.start(oneshot_lines: true)

    # To handle execution with exit immediatly
    at_exit do
      OneshotCov.emit(force_emit: true)
    end
  end

  def emit(force_emit: false)
    @reporter.emit(force_emit)
  end

  def configure(target_path: Rails.root, logger: nil, emit_term: nil)
    if logger.nil?
      raise ArgumentError.new("Specifying logger in `OneshotCov.configure` is mandatory`")
    end

    target_path_by_pathname =
      if target_path.is_a? Pathname
        target_path
      else
        Pathname.new(target_path)
      end
    @reporter = OneshotCov::Reporter.new(
      target_path: target_path_by_pathname.cleanpath.to_s + "/",
      logger: logger,
      emit_term: emit_term,
    )
  end
end