unless defined? Rails::Railtie
  raise "You need to install and require Rails to use this integration"
end

module OneshotCov
  class Railtie < Rails::Railtie
    initializer 'oneshot_cov.configure' do |app|
      app.middleware.use OneshotCov::Middleware
    end
  end
end