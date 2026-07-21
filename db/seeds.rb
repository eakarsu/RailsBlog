if ENV["BOOTSTRAP_ADMIN_EMAIL"].present?
  password = ENV.fetch("BOOTSTRAP_ADMIN_PASSWORD")
  raise "BOOTSTRAP_ADMIN_PASSWORD must be at least 12 characters" if password.length < 12

  User.find_or_create_by!(email: ENV.fetch("BOOTSTRAP_ADMIN_EMAIL").downcase) do |user|
    user.display_name = ENV.fetch("BOOTSTRAP_ADMIN_NAME", "Administrator")
    user.role = "admin"
    user.password = password
    user.password_confirmation = password
  end
end
