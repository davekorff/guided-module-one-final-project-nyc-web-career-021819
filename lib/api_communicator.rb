require 'rest-client'
require 'json'
# require 'pry'



def get_data(user)
  response_string = RestClient.get("https://api.github.com/users/#{user}/repos")
  response_hash = JSON.parse(response_string)


  username = response_hash.first["owner"]["login"]

  user_info = {
                name: response_hash.first["owner"]["login"],
                mod: 0,
                github_username: response_hash.first["owner"]["login"],
                profile_url: response_hash.first["owner"]["html_url"],
              }

  user = User.find_or_create_by(name: user_info[:name], mod: user_info[:mod], github_username: user_info[:github_username], profile_url: user_info[:profile_url])

  repo_info = []


  response_hash.each do |repo|
    repo_info << {
                  project_name: repo["name"],
                  description: repo["description"],
                  repo_url: repo["html_url"]
                  }
  end

  repo_info.each do |repo|
    new_repo = Repo.find_or_create_by(project_name: repo[:project_name], description: repo[:description], repo_url: repo[:repo_url] )
    user.repos << new_repo unless user.repos.include?(new_repo)
  end
end