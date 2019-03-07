require_relative '../config/environment'

class CommandLineInterface

  def initialize
    remove_user_from_repo = -> {
      UserRepo.destroy(@user_repo.id)
      puts "Deleted #{@user.name} from #{@selected_repo.project_name}!"
    }
    add_user_to_repo = -> {
      puts "Who do you want to add? (enter username with *EXACT* spelling and capitalization):"
      input = gets_user_input
      if !username_exists?(input)
        #making an API call
        get_data(input)
      end
      @user = find_user(input)
      if @user == false
        puts "That user doesn't exist"
      else
        if username_exists?(@user.github_username)
          if already_on_repo?(@user, @selected_repo)
            puts "#{@user.name} is already working on #{@selected_repo.project_name}"
          else
            @user.repos << @selected_repo
            puts "#{@user.name} was successfully added to #{@selected_repo.project_name}"
          end
        end
      end
    }
    delete_repo = -> {
      puts "Are you sure you want to delete #{@selected_repo.project_name}? (y/n)"
      input = gets_user_input[0].downcase
      if input == "y"
        Repo.destroy(@selected_repo.id)
        puts "Deleted #{@selected_repo.project_name}!"
      else
        puts "Good idea."
      end
    }
    do_nothing = -> {}

    show_repo_url = -> {
      puts
      puts "#{@selected_repo.project_name} - #{@selected_repo.repo_url}"
      `open #{@selected_repo.repo_url}`
    }

    update_repo_name = -> {
      puts "Enter new Repo name:"
      input = gets_user_input
      @selected_repo.update_attribute(:project_name, input)
      puts "Updated repo name to #{@selected_repo.project_name}"
    }

    update_repo_description = -> {
      puts "Enter new Repo description:"
      input = gets_user_input
      @selected_repo.update_attribute(:description, input)
      puts "Updated description to #{@selected_repo.description}"
    }

    @user_actions = [
      {description: "Remove current user from repo",
      action: remove_user_from_repo},
      {description: "Add User to repo",
      action: add_user_to_repo},
      {description: "Delete repo",
      action: delete_repo},
      {description: "Return to Menu",
      action: do_nothing},
      {description: "Show and open Repo URL",
        action: show_repo_url}
    ]

    @keyword_actions = [
      {description: "Show and open Repo URL",
      action: show_repo_url},
      {description: "Update Repo Name",
      action: update_repo_name},
      {description: "Updates Repo Description",
      action: update_repo_description},
    ]
  end

  #Starts Github Repo Explorer
  def run
    greet
    menu
  end

  #Greeting Screen
  def greet
    puts
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    puts "Welcome to GitHub Repo Explorer"
    puts "We can help you find github repos."
  end

  #Main Menu
  def menu
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    puts "What would you like to do? (choose number)"
    puts "Enter 'exit' at anytime to close application"
    puts
    puts "1. Find all repos by username"
    puts "2. Search repos by keyword"
    puts "3. Find all collaborators for a repo"
          # *TO DO* add functionality to add users to repo
    puts "4. Create new user in local database"
    puts
    main_menu_loop
  end

  def main_menu_loop
    input = gets_user_input
      case input.to_i
      when 1
        find_by_username_menu
        input = gets_user_input
        user_actions(input.to_i)
        menu
      when 2
        find_by_keyword_menu
        input = gets_user_input
        keyword_actions(input.to_i)
        menu
      when 3
        find_all_collabs_for_repo
      when 4
        create_new_user
      end
  end

  #gets the user input. If input is "exit", leave the program.
  def gets_user_input
    input = gets.chomp
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # binding.pry

    if input == "exit"
      exit
    end

    return input
  end

  #checks to see if a github username exists
  def username_exists?(github_username)
    !!User.all.find_by(github_username: github_username)
  end

  #checks to see if a repo has a user.
  def already_on_repo?(user, repo)
    repo.users.include?(user)
  end

  #finds a user through github username
  def find_user(github_username)
    if username_exists?(github_username)
      User.all.find_by(github_username: github_username)
    else
      false
    end
  end

  #Find by username Menu options
  def find_by_username_menu
    puts
    puts "Enter a github username with *EXACT* capitalization to list that user's repos:"
    input = gets_user_input
    #if username exists in our DB, don't make API call.
    if !username_exists?(input)
      #making an API call
      get_data(input)
    end
    if find_user(input) == false
      puts "That user either doesn't exist, doesn't exist by that exact username, or doesn't have any repos."
      menu
    else
      @user = find_user(input)
    end
    @repos = find_repos(@user)
    if show_repos(@repos) == false
      puts "User has no repos"
      menu
    end
    find_by_username_sub_menu
  end

  def user_actions(input)
    @user_actions[input - 1][:action].()
  end

  def keyword_actions(input)
    @keyword_actions[input - 1][:action].()
  end

  def find_by_username_sub_menu
    puts "Enter repo number to view repo details"
    input = gets_user_input.to_i
    if input > @repos.count
      puts "That repo doesn't exist."
      find_by_username_sub_menu
    else
      @selected_repo = @repos[input- 1]
      @user_repo = find_user_repo(@user, @selected_repo)
      puts "Repo name: #{@repos[input - 1].project_name}"
      puts "Description: #{@repos[input - 1].description}"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "What would you like to do?"
      @user_actions.each_with_index do |user_action, index|
        puts "#{index + 1}. #{user_action[:description]}"
      end
    end
  end

  def find_by_keyword_menu
    puts "Enter keyword (one word only please):"
    input = gets_user_input.downcase
    #Making a call to the API
    search_github(input)
    @repos_by_keyword = find_repo_by_keyword(input)
    if @repos_by_keyword.empty?
      puts "There are no repos with '#{input}' in the description."
      find_by_keyword_menu
    else
      @repos_by_keyword.each_with_index do |repo, index|
        puts "#{index + 1}. #{repo.project_name}"
        puts "Description: #{repo.description}"
      end
    end
    find_by_keyword_sub_menu
  end

  def find_by_keyword_sub_menu
    puts "Enter repo number to view repo details"
    input = gets_user_input.to_i
    @selected_repo = @repos_by_keyword[input - 1]
    if input > @repos_by_keyword.count
      puts "That repo doesn't exist."
      find_by_keyword_sub_menu
    else
      puts "#{@selected_repo.project_name} - #{@selected_repo.description}"
      @keyword_actions.each_with_index do |user_action, index|
        puts "#{index + 1}. #{user_action[:description]}"
      end
    end
  end

  def find_all_collabs_for_repo
    puts "Enter a repo name with *EXACT* spelling and capitalization:"
    input = gets_user_input
    repo_by_project_name = find_repo_by_project_name(input)
    if repo_by_project_name == nil
      puts "No repo found"
    else
      repo_by_project_name.users.each do |user|
        puts user.github_username
      end
    end
    menu
  end

  def create_new_user
    puts "Enter new user's github username:"
    github_username = gets_user_input
    if username_exists?(github_username)
      puts "#{github_username} already exists"
      create_new_user
    end
    puts "Enter new user's full name:"
    full_name = gets_user_input
    puts "Enter new user's mod:"
    #Todo- make the user only able to input a number from 1-5
    mod = gets_user_input
    new_user = User.create(name: full_name, mod: mod, github_username: github_username, profile_url: "https://github.com/#{github_username}")
    puts "Created #{github_username}!"
    menu
  end

  #Finds the USER_REPO for a given user and repo
  def find_user_repo(user, repo)
    UserRepo.find_by("user_id = ? AND repo_id = ?", user.id, repo.id)
  end

  #Returns all of a user's repos
  def find_repos(user)
    user.repos
  end

  #Displays repos if there are any repos.
  def show_repos(repos)
    if repos.length == 0
      false
    else
      repos.each_with_index do |repo, index|
        puts "#{index+1}. #{repo.project_name}"
      end
    end
  end

  #Selects all repos that have the given keyword in the description
  def find_repo_by_keyword(keyword)
    Repo.all.select do |repo|
      if repo.description != nil
        repo.description.downcase.include?(keyword)
      end
    end
  end

  #Finds the first repo with a given project name
  def find_repo_by_project_name(project_name)
    Repo.all.find_by(project_name: project_name)
  end
end
