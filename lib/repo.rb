class Repo < ActiveRecord::Base
  has_many :user_repos
  has_many :users, through: :user_repos
end
