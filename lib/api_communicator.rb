require 'rest-client'
require 'json'

def get_data(user)

  response_string = ""
  RestClient.get("https://api.github.com/users/#{user}/repos") do |response, request, result| 
    if response.code != 200
      return
    else
      response_string = response.body
    end
  end
  
  response_hash = JSON.parse(response_string)

  if response_hash.empty?
    return
  end
  
  user_info = {
                name: response_hash.first["owner"]["login"],
                mod: 0,
                github_username: response_hash.first["owner"]["login"],
                profile_url: response_hash.first["owner"]["html_url"],
              }

  user = User.find_or_create_by(name: user_info[:name], mod: user_info[:mod], github_username: user_info[:github_username], profile_url: user_info[:profile_url])

  repo_info = response_hash.map do |repo|
    {
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


def search_github(keyword)
  response_string = ""
  RestClient.get("https://api.github.com/search/repositories?q=#{keyword}&sort=stars&order=desc") do |response, request, result|
    if response.code != 200
      return
    else
    response_string = response.body
    end
  end

  response_hash = JSON.parse(response_string)

  response_hash["items"].each do |repo|
    new_repo = Repo.find_or_create_by(project_name: repo["name"], description: repo["description"],repo_url: repo["html_url"])
    new_repo.description ||= keyword
    new_repo.save
  end
end
