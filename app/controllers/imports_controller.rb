class ImportsController < ApplicationController
  before_action :authenticate!
  before_action :require_editor!

  def new; end

  def create
    upload = params[:file]
    render(json: { error: "file is required" }, status: :unprocessable_entity) and return unless upload.respond_to?(:read)
    run = Publishing::Importer.call(json: upload.read(5.megabytes + 1), actor: current_user, dry_run: params[:commit_import] != "true")
    render json: { id: run.id, status: run.status, dry_run: run.dry_run, errors: run.reported_errors }, status: run.status == "rejected" ? :unprocessable_entity : :ok
  rescue Publishing::Importer::InvalidPayload => error
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
