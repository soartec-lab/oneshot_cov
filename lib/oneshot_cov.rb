require "coverage"
require "digest/md5"

require "oneshot_cov/logger"
require "oneshot_cov/railtie" if defined?(Rails)

module OneshotCov
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    ensure
      if Coverage.running?
        OneshotCov.emit
      end
    end
  end

  OneshotLog = Struct.new(:path, :md5_hash, :lines)

  class Reporter
    def initialize(target_path:, logger:, emit_term: nil)
      @target_path = target_path
      @logger = logger
      @emit_term = emit_term
      if @emit_term
        @next_emit_time = Time.now.to_i + rand(@emit_term)
      end

      if defined?(Bundler)
        @bundler_path = Bundler.bundle_path.to_s
      end
    end

    def emit(force_emit)
      if !force_emit
        if !time_to_emit?
          return
        end
      end

      logs =
        Coverage.result(clear: true, stop: false).
        select { |k, v| is_target?(k, v) }.
        map do |filepath, v|
          OneshotLog.new(relative_path(filepath), md5_hash_for(filepath), v[:oneshot_lines])
        end

      if logs.size > 0
        @logger.post(logs)
      end
    end

    private

    def time_to_emit?
      if @emit_term
        if @next_emit_time > Time.now.to_i
          return false # Do not emit until next_emit_time
        else
          @next_emit_time += @emit_term
        end
      end
      true
    end

    def is_target?(filepath, value)
      return false if value[:oneshot_lines].empty?
      return false if !filepath.start_with?(@target_path)
      return false if @bundler_path && filepath.start_with?(@bundler_path)
      true
    end

    def relative_path(filepath)
      filepath[@target_path.size..-1]
    end

    def md5_hash_cache
      @md5_hash_cache ||= {}
    end

    def md5_hash_for(filepath)
      if md5_hash_cache.key? filepath
        md5_hash_cache[filepath]
      else
        md5_hash_cache[filepath] = Digest::MD5.file(filepath).hexdigest
      end
    end
  end

  module_function

  def start
    Coverage.start(oneshot_lines: true)

    # To handle execution with exit immediatly
    at_exit do
      OneshotCov.emit(force_emit: true)
    end
  end

  def emit(force_emit: false)
    @reporter&.emit(force_emit)
  end

  def configure(target_path:, logger: OneshotCov::Logger.new, emit_term: nil)
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