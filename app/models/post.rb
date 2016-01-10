class Post < ActiveRecord::Base
  validates :title, :presence => true, :length => {:minimum => 2}
  validates :title, :exclusion => {:in => ["Title"] }

  has_many :comments
end
