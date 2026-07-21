class Rack::Attack
  throttle("comments/ip", limit: 5, period: 60) do |request|
    request.ip if request.post? && request.path.match?(%r{\A/posts/[^/]+/comments\z})
  end

  throttle("login/ip", limit: 10, period: 5.minutes) do |request|
    request.ip if request.post? && request.path == "/session"
  end

  self.throttled_responder = lambda do |_request|
    [429, { "Content-Type" => "application/json", "Retry-After" => "60" }, [{ error: "rate_limited" }.to_json]]
  end
end

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?
Rails.application.config.middleware.use Rack::Attack
