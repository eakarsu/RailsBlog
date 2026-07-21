Rails.application.configure do
  config.cache_classes = true
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.action_dispatch.use_authenticated_cookie_encryption = false
  config.active_support.use_authenticated_message_encryption = false
  config.active_storage.service = :test
  config.active_support.deprecation = :stderr
  config.active_record.maintain_test_schema = false
  config.active_record.dump_schema_after_migration = false
end
