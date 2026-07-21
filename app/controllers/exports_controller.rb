class ExportsController < ApplicationController
  def show
    result = Publishing::Exporter.call(actor: current_user)
    response.set_header("X-Content-SHA256", result[:sha256])
    response.set_header("Content-Disposition", "attachment; filename=rails-blog-export-v1.json")
    render json: result[:payload]
  end
end
