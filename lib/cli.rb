require_relative '../config/environment'


class CommandLineInterface
  def greet
    puts
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    puts "Welcome to GitHub Repo Explorer"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    puts "We can help you find your github repos."
    puts "Type 'ctrl' + 'c' at any time to close the application."
    puts
  end

  def gets_user_input
    input = gets.chomp
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    return input
  end

  def username_exists?(github_username)
    !!User.all.find_by(github_username: github_username)
  end

  def already_on_repo?(user, repo)
    repo.users.include?(user)
  end

  def find_user(github_username)
    if username_exists?(github_username)
      User.all.find_by(github_username: github_username)
    else
      false
    end
  end

  def run
    greet
    menu
  end

  def menu
    puts "What would you like to do?"
    puts "1. Find all repos by username"
    puts "2. Find all repos with a keyword"
    puts "3. Find all collaborators for a repo"
          # *TO DO* add functionality to add users to repo
    puts "4. Create new user"
    main_menu_loop
  end

  def find_by_username_menu
    puts "Enter a github username **WITH EXACT CAPITALIZATION** to list that user's repos:"
    input = gets_user_input
    #making an API call
    get_data(input)
    if find_user(input) == false
      puts "That user doesn't exist! (or doesn't exist by that exact username)"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      menu
    else
      @user = find_user(input)
    end
    @repos = find_repos(@user)
    if show_repos(@repos) == false
      puts "User has no repos"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      menu
    end
    find_by_username_sub_menu
  end

  def find_by_username_sub_menu
    puts "Select repo number to view repo details"
    input = gets_user_input
    @selected_repo = @repos[input.to_i - 1]
    @user_repo = find_user_repo(@user, @selected_repo)
    puts "Repo name: #{@repos[input.to_i - 1].project_name}"
    puts "Description: #{@repos[input.to_i - 1].description}"
    puts "What would you like to do?"
    puts "1. Remove current user from repo"
    puts "2. Add another user to repo"
    puts "3. Delete repo"
  end

  def remove_user_from_repo
    UserRepo.destroy(@user_repo.id)
    puts "Deleted #{@user.name} from #{@selected_repo.project_name}!"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu
  end

  def add_user_to_repo
    puts "Who do you want to add? (enter username with *EXACT* spelling and capitalization):"
    input = gets_user_input
    @user = find_user(input)
    if @user == false
      puts "That user doesn't exist"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    else
      if username_exists?(@user.github_username)
        if already_on_repo?(@user, @selected_repo)
          puts "#{@user.name} is already working on #{@selected_repo.project_name}"
          puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        else
          @user.repos << @selected_repo
          puts "#{@user.name} was successfully added to #{@selected_repo.project_name}"
          puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        end
      end
    end
    menu
  end

  def delete_repo
    puts "Are you sure you want to delete #{@selected_repo.project_name}? (y/n)"
    input = gets_user_input[0].downcase
    if input == "y"
      Repo.destroy(@selected_repo.id)
      puts "Deleted #{@selected_repo.project_name}!"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    else
      puts "Good idea. Never delete your repos!"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end
    menu
  end

  def find_by_keyword_menu
    puts "Enter keyword:"
    input = gets_user_input.downcase
    @repos_by_keyword = find_repo_by_keyword(input)
    if @repos_by_keyword.empty?
      puts "There are no repos with '#{input}' in the description."
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    else
      @repos_by_keyword.each_with_index do |repo, index|
        puts "#{index + 1}. #{repo.project_name} - #{repo.description}"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      end
    end
    find_by_keyword_sub_menu
  end

  def find_by_keyword_sub_menu
    puts "Select repo number to view repo details"
    input = gets_user_input
    @selected_repo = @repos_by_keyword[input.to_i - 1]
    puts "#{@selected_repo.project_name} - #{@selected_repo.description}"
    puts "1. Show Repo URL"
    puts "2. Update Repo name"
    puts "3. Update Repo description"
  end

  def show_repo_url
    puts "#{@selected_repo.project_name} - #{@selected_repo.repo_url}"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # *TO DO* add functionality to open url in browser
    menu
  end

  def update_repo_name
    puts "Enter new Repo name:"
    input = gets_user_input
    @selected_repo.update_attribute(:project_name, input)
    puts "Updated repo name to #{@selected_repo.project_name}"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu
  end

  def update_repo_description
    puts "Enter new Repo description:"
    input = gets_user_input
    @selected_repo.update_attribute(:description, input)
    puts "Updated description to #{@selected_repo.description}"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu
  end

  def find_all_collabs_for_repo
    puts "Enter a repo name (exact spelling and capitalization matter):"
    input = gets_user_input
    repo_by_project_name = find_repo_by_project_name(input)
    if repo_by_project_name == nil
      puts "No repo found"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    else
      repo_by_project_name.users.each do |user|
        puts user.name
      end
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end
    menu
  end

  def create_new_user
    puts "Enter new user's github username:"
    github_username = gets_user_input
    if username_exists?(github_username)
      puts "#{github_username} already exists"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      create_new_user
    end
    puts "Enter new user's full name:"
    full_name = gets_user_input
    puts "Enter new user's mod:"
    mod = gets_user_input
    new_user = User.create(name: full_name, mod: mod, github_username: github_username, profile_url: "https://github.com/#{github_username}")
    puts "Created #{github_username}!"
    puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu
  end

  def main_menu_loop
    while user_input != "exit"
      case @last_input.to_i
      when 1
        find_by_username_menu
        while user_input != "exit"
          case @last_input.to_i
          when 1
            remove_user_from_repo
          when 2
            add_user_to_repo
          when 3
            delete_repo
          end
        end
      when 2
        find_by_keyword_menu
        while user_input != "exit"
          case @last_input.to_i
          when 1
            show_repo_url
          when 2
            update_repo_name
          when 3
            update_repo_description
          end
        end
      when 3
        find_all_collabs_for_repo
      when 4
        create_new_user
      end
    end
  end

  def find_user_repo(user, repo)
    UserRepo.find_by("user_id = ? AND repo_id = ?", user.id, repo.id)
  end

  # def remove_user_from_repo(user_repo)
  #   user_repo.destroy
  # end


  def find_repos(user)
    user.repos
  end

  def show_repos(repos)
    if repos.length == 0
      # puts "#{@user.name} has no repos"
      false
    else
      repos.each_with_index do |repo, index|
        puts "#{index+1}. #{repo.project_name}"
      end
    end
  end

  def find_repo_by_keyword(keyword)
    Repo.all.select do |repo|
      if repo.description != nil
        repo.description.downcase.include?(keyword)
      end
    end
  end

  def find_repo_by_project_name(project_name)
    Repo.all.find_by(project_name: project_name)
  end

  def user_input
    @last_input = gets.strip
  end

end
