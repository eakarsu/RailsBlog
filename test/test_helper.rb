ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)

  def create_user(role: "author", email: nil, name: nil)
    User.create!(email: email || "#{role}-#{SecureRandom.hex(4)}@example.test",
                 display_name: name || role.capitalize, role: role,
                 password: "correct horse battery staple", password_confirmation: "correct horse battery staple")
  end

  def create_post(author:, status: "draft", title: "A substantial article")
    attributes = { author: author, title: title, body: "A thoughtful body with enough context.", status: status }
    attributes[:published_at] = Time.current if status == "published"
    Post.create!(attributes)
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user, password: "correct horse battery staple")
    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end
end
