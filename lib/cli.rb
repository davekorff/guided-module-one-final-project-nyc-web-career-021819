class CommandLineInterface
  def greet
    puts "Welcome to the GitHub Repo Explorer"
    puts "We can help you find your github repos."
    # puts "Type 'exit' at any time to close the application."
  end

  def gets_user_input
    gets.chomp
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
    puts "1. Find all projects by username"
    puts "2. Find all projects with a keyword"
    puts "3. Find all collaborators for a project"
          # *TO DO* add functionality to add users to project
    main_menu_loop
  end

  def find_by_username_menu
    puts "Enter a github username **WITH EXACT CAPITALIZATION** to list that user's projects:"
    input = gets_user_input
    if find_user(input) == false
      puts "That user doesn't exist! (or doesn't exist by that exact username)"
      menu
    else
      @user = find_user(input)
    end
    @repos = find_repos(@user)
    if show_repos(@repos) == false
      puts "User has no repos"
      menu
    end
    select_repo_by_username_menu
  end

  def select_repo_by_username_menu
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
    menu
  end

  def add_user_to_repo
    puts "Who do you want to add? (enter username with *EXACT* spelling and capitalization):"
    input = gets_user_input
    # puts input
    @user = find_user(input)
    if username_exists?(@user.github_username)
      if already_on_repo?(@user, @selected_repo)
        puts "#{@user.name} is already working on #{@selected_repo.project_name}"
      else
        @user.repos << @selected_repo
        puts "#{@user.name} was successfully added to #{@selected_repo.project_name}"
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
    else
      puts "Good idea. Never delete your repos!"
    end
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
        break
      when 2
        puts "Enter keyword:"
        input = gets_user_input.downcase
        repos_by_keyword = find_repo_by_keyword(input)
        if repos_by_keyword.empty?
          puts "There are no repos with '#{input}' in the description."
        else
          repos_by_keyword.each_with_index do |repo, index|
            puts "#{index + 1}. #{repo.project_name} - #{repo.description}"
          end
        end
        puts "Select repo number to view repo details"
        input = gets_user_input
        selected_repo = repos_by_keyword[input.to_i - 1]
        puts "#{selected_repo.project_name} - #{selected_repo.description}"
        puts "1. Show Repo URL"
        puts "2. Update Repo name"
        puts "3. Update Repo description"
        while user_input != "exit"
          case @last_input.to_i
          when 1
            # show repo URL
            puts "#{selected_repo.project_name} - #{selected_repo.repo_url}"
            # add functionality to open url in browser
            break
          when 2
            # update repo name
            puts "Enter new Repo name:"
            input = gets_user_input
            selected_repo.update_attribute(:project_name, input)
            puts selected_repo.project_name
            break
          when 3
            # update repo description
            puts "Enter new Repo description:"
            input = gets_user_input
            selected_repo.update_attribute(:description, input)
            puts selected_repo.description
            break
          end
        end
      when 3
        puts "Enter a project name:"
        input = gets_user_input
        repo_by_project_name = find_repo_by_project_name(input)
        if repo_by_project_name == nil
          puts "No project found"
        else
          repo_by_project_name.users.each do |user|
            puts user.name
          end
        end
      else
        menu
        break
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
      repo.description.downcase.include?(keyword)
    end
  end

  def find_repo_by_project_name(project_name)
    Repo.all.find_by(project_name: project_name)
  end

  def user_input
    @last_input = gets.strip
  end

end
