class CategoriesController < ApplicationController
  before_action :authenticate!
  before_action :require_editor!
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.order(:name)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    @category.save ? redirect_to(categories_path, notice: "Category created.") : render(:new, status: :unprocessable_entity)
  end

  def edit; end

  def update
    @category.update(category_params) ? redirect_to(categories_path, notice: "Category updated.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @category.destroy!
    redirect_to categories_path, notice: "Category deleted."
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
