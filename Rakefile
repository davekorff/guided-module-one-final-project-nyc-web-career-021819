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

task :dbempty? do
  if Repo.all.empty? && User.all.empty? && UserRepo.all.empty?
    puts "~~~~~~~~~~~~~~~~"
    puts "DATABASE EMPTY"
    puts "~~~~~~~~~~~~~~~~"
  else
    puts "~~~~~~~~~~~~~~~~"
    puts "DATABASE NOT EMPTY"
    puts "~~~~~~~~~~~~~~~~"
  end
end
