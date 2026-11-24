require 'health_check'

class HealthCheckMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] =~ %r[\A/health-check/?\Z]
      [
        200,
        {
          'content-type' => 'application/json',
        },
        [HealthCheck.checkup(env).to_json]
      ]
    else
      @app.call(env)
    end
  end
end
