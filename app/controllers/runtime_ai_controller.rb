require "net/http"
require "uri"

class RuntimeAiController < ApplicationController
  skip_forgery_protection only: :create, if: -> { request.format.json? }
  before_action :authenticate!

  def create
    prompt = params[:prompt].to_s.strip
    return render json: { error: "prompt_required" }, status: :bad_request if prompt.empty?

    base_url = ENV.fetch("OPENROUTER_BASE_URL")
    model = ENV.fetch("OPENROUTER_MODEL")
    uri = URI.parse("#{base_url}/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV.fetch('OPENROUTER_API_KEY')}"
    request["Content-Type"] = "application/json"
    request.body = {
      model: model,
      messages: [
        { role: "system", content: "You are an editorial planning assistant. Return substantive, concise publishing guidance with risks and next actions." },
        { role: "user", content: prompt }
      ],
      temperature: 0.2
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", read_timeout: 90) { |http| http.request(request) }
    raise "OpenRouter returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    content = JSON.parse(response.body).dig("choices", 0, "message", "content").to_s.strip
    raise "OpenRouter returned empty content" if content.empty?

    result = RuntimeAiResult.create!(
      user: current_user,
      prompt: prompt,
      content: content,
      provider: "openrouter",
      model: model
    )
    render json: { content: content, provider: result.provider, model: result.model, persistedId: result.id }
  rescue KeyError => error
    render json: { error: error.message }, status: :service_unavailable
  rescue StandardError => error
    Rails.logger.error("runtime_ai_error=#{error.class}: #{error.message}")
    render json: { error: "ai_provider_request_failed" }, status: :bad_gateway
  end
end
