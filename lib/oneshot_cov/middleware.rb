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
end