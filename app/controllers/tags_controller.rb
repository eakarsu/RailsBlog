class TagsController < ApplicationController
  before_action :authenticate!
  before_action :require_editor!
  before_action :set_tag, only: %i[edit update destroy]

  def index
    @tags = Tag.order(:name)
  end

  def new
    @tag = Tag.new
  end
  def edit; end

  def create
    @tag = Tag.new(tag_params)
    @tag.save ? redirect_to(tags_path, notice: "Tag created.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @tag.update(tag_params) ? redirect_to(tags_path, notice: "Tag updated.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @tag.destroy!
    redirect_to tags_path, notice: "Tag deleted."
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
