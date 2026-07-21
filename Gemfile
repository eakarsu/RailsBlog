source "https://rubygems.org"

ruby ">= 3.2.0"

gem "rails", "~> 8.1.2", ">= 8.1.2.1"
gem "puma", "~> 7.2", ">= 7.2.1"
gem "bcrypt", "~> 3.1"
gem "rack-attack", "~> 6.7"
gem "jbuilder", "~> 2.11"
gem "sprockets-rails", "~> 3.5"
gem "nokogiri", ">= 1.19.4"
gem "rails-html-sanitizer", ">= 1.7.1"
gem "net-imap", ">= 0.5.15"

group :development, :test do
  gem "sqlite3", ">= 2.9.5"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
end

group :test do
  gem "capybara", "~> 3.40"
end

group :production do
  gem "pg", "~> 1.5"
end
