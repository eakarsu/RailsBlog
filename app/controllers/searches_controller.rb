class SearchesController < ApplicationController
  def show
    @query = params[:q].to_s.strip.first(100)
    @posts = if @query.present?
               escaped = ActiveRecord::Base.sanitize_sql_like(@query)
               Post.published.where("lower(title) LIKE :q OR lower(body) LIKE :q", q: "%#{escaped.downcase}%").recent_first.limit(30)
             else
               Post.none
             end
  end
end
