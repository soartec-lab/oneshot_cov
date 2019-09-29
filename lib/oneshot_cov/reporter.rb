module OneshotCov

  OneshotLog = Struct.new(:path, :lines)

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
          OneshotLog.new(relative_path(filepath), v)
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
      return false if value.empty?
      return false if !filepath.start_with?(@target_path)
      return false if @bundler_path && filepath.start_with?(@bundler_path)
      true
    end

    def relative_path(filepath)
      filepath[@target_path.size..-1]
    end
  end
end