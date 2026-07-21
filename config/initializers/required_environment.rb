if Rails.env.production?
  %w[DATABASE_URL SECRET_KEY_BASE].each do |name|
    value = ENV[name].to_s
    raise "#{name} is required in production" if value.empty?
  end
  raise "SECRET_KEY_BASE must be at least 64 characters" if ENV.fetch("SECRET_KEY_BASE").length < 64
end
