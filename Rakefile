require_relative 'config/environment'
require 'sinatra/activerecord/rake'

desc 'starts a console'
task :console do
  Pry.start
end

task :reset do
  Repo.destroy_all
  User.destroy_all
  UserRepo.destroy_all
end
