require 'scm/repository'
require 'scm/commits/git'

module SCM
  #
  # Interacts with Git repositories.
  #
  class Git < Repository

    # The two-letter Git status codes
    STATUSES = {
      ' M' => :modified,
      'M ' => :staged,
      'A ' => :added,
      'D ' => :deleted,
      'R ' => :renamed,
      'C ' => :copied,
      'U ' => :unmerged,
      '??' => :untracked
    }

    #
    # Creates a Git repository.
    #
    # @param [String] path
    #   The path to the repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :bare
    #   Specifies whether to create a bare repository.
    #
    # @return [Git]
    #   The initialized Git repository.
    #
    # @raise [RuntimeError]
    #   Could not initialize the Git repository.
    #
    def self.create(path,options={})
      path = File.expand_path(path)

      arguments = []

      arguments << '--bare' if options[:bare]
      arguments << path

      FileUtils.mkdir_p(path)

      unless system('git','init',*arguments)
        raise("unable to initialize Git repository #{path.dump}")
      end

      return new(path)
    end

    #
    # Clones a remote Git repository.
    #
    # @param [URI, String] uri
    #   The URI of the remote repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :bare
    #   Performs a bare clone of the repository.
    #
    # @option options [Boolean] :mirror
    #   Mirrors the remote repository.
    #
    # @option options [Integer] :depth
    #   Performs a shallow clone.
    #
    # @option options [Boolean] :submodules
    #   Recursively initialize each sub-module.
    #
    # @option options [String, Symbol] :branch
    #   The branch to specifically clone.
    #
    # @option options [String] :dest
    #   The destination directory to clone into.
    #
    # @return [Boolean]
    #   Specifies whether the clone was successful.
    #
    def self.clone(uri,options={})
      arguments = []

      arguments << '--bare'   if options[:bare]
      arguments << '--mirror' if options[:mirror]

      if options[:depth]
        arguments << '--depth' << options[:depth]
      end

      if options[:branch]
        arguments << '--branch' << options[:branch]
      end

      arguments << '--recurse-submodules' if options[:submodules]

      arguments << '--' unless arguments.empty?

      arguments << uri
      arguments << options[:dest] if options[:dest]

      system('git','clone',*arguments)
    end

    #
    # Queries the status of the repository.
    #
    # @param [Array] paths
    #   The optional paths to query.
    #
    # @return [Hash{String => Symbol}]
    #   The file paths and their statuses.
    #
    def status(*paths)
      statuses = {}

      popen('git status --porcelain',*paths) do |line|
        status = line[0,2]
        path = line[3..-1]

        statuses[path] = STATUSES[status]
      end

      return statuses
    end

    #
    # Adds paths to the repository.
    #
    # @param [Array] paths
    #   The paths to add to the repository.
    #
    def add(*paths)
      git(:add,*paths)
    end

    #
    # Moves a file or directory.
    #
    # @param [String] source
    #   The path of the source file/directory.
    #
    # @param [String] dest
    #   The new destination path.
    #
    # @param [Boolean] force
    #   Specifies whether to force the move.
    #
    def move(source,dest,force=false)
      arguments = []

      arguments << '-f' if force
      arguments << source << dest

      git(:mv,*arguments)
    end

    #
    # Removes files or directories.
    #
    # @param [String, Array] paths
    #   The path(s) to remove.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :force (false)
    #   Specifies whether to forcibly remove the files/directories.
    #
    # @option options [Boolean] :recursive (false)
    #   Specifies whether to recursively remove the files/directories.
    #
    def remove(paths,options={})
      arguments = []

      arguments << '-f' if options[:force]
      arguments << '-r' if options[:recursive]
      arguments += ['--', *paths]

      git(:rm,*arguments)
    end

    #
    # Makes a Git commit.
    #
    # @param [String] message
    #   The message for the commit.
    #
    # @param [Hash] options
    #   Commit options.
    #
    # @option options [String] :paths
    #   The path of the file to commit.
    #
    # @return [Boolean]
    #   Specifies whether the commit was successfully made.
    #
    def commit(message=nil,options={})
      arguments = []
      
      if message
        arguments << '-m' << message
      end

      if options[:paths]
        arguments += ['--', *options[:paths]]
      end

      git(:commit,*arguments)
    end

    #
    # Lists Git branches.
    #
    # @return [Array<String>]
    #   The branch names.
    #
    def branches
      branches = []

      popen('git branch') do |line|
        branches << line[2..-1]
      end

      return branches
    end

    #
    # The current branch.
    #
    # @return [String]
    #   The name of the current branch.
    #
    def current_branch
      popen('git branch') do |line|
        return line[2..-1] if line[0,1] == '*'
      end
    end

    #
    # Swtiches to another Git branch.
    #
    # @param [String, Symbol] name
    #   The name of the branch to switch to.
    #
    # @param [Hash] options
    #   Additional options.
    #
    #   @option options [Boolean] :quiet 
    #   Switch branch quietly.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    def switch_branch(name, options={})
      arguments = ""
      arguments << '-q' if options[:quiet]
      git(:checkout, arguments, name)
    end

    #
    # Deletes a branch.
    #
    # @param [String] name
    #   The name of the branch to delete.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully deleted.
    #
    def delete_branch(name)
      git(:branch,'-d',name)
    end

    #
    # Lists Git tags.
    #
    # @return [Array<String>]
    #   The tag names.
    #
    def tags
      tags = []

      popen('git tag') do |line|
        tags << line[2..-1]
      end

      return tags
    end

    #
    # Creates a Git tag.
    #
    # @param [String] name
    #   The name for the tag.
    #
    # @param [String] commit
    #   The commit to create the tag at.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully created.
    #
    def tag(name,commit=nil)
      arguments = []
      arguments << commit if commit

      git(:tag,name,*arguments)
    end

    #
    # Deletes a Git tag.
    #
    # @param [String] name
    #   The name of the tag.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully deleted.
    #
    def delete_tag(name)
      git(:tag,'-d',name)
    end

    #
    # Prints the Git log.
    #
    # @param [String] :commit
    #   Commit to begin the log at.
    #
    # @param [String] :paths
    #   File to list commits for.
    #
    def log(options={})
      arguments = []

      arguments << options[:commit] if options[:commit]
      
      if options[:paths]
        arguments += ['--', *options[:paths]]
      end

      git(:log,*arguments)
    end

    #
    # Pushes changes to the remote Git repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :mirror
    #   Specifies to push all refs under `.git/refs/`.
    #
    # @option options [Boolean] :all
    #   Specifies to push all refs under `.git/refs/heads/`.
    #
    # @option options [Boolean] :tags
    #   Specifies to push all tags.
    #
    # @option options [Boolean] :force
    #   Specifies whether to force pushing the changes.
    #
    # @option options [String, Symbol] :repository
    #   The remote repository to push to.
    #
    # @option options [String, Symbol] :branch
    #   The specific branch to push.
    #
    # @return [Boolean]
    #   Specifies whether the changes were successfully pushed.
    #
    def push(options={})
      arguments = []

      if options[:mirror]
        arguments << '--mirror'
      elsif options[:all]
        arguments << '--all'
      elsif options[:tags]
        arguments << '--tags'
      end

      arguments << '-f' if options[:force]
      arguments << options[:repository] if options[:repository]

      if options[:branch]
        arguments << 'origin' unless options[:repository]
        arguments << options[:branch]
      end

      git(:push,*arguments)
    end

    #
    # Pulls changes from the remote Git repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :force
    #   Specifies whether to force pushing the changes.
    #
    # @option options [String, Symbol] :repository
    #   The remote repository to push to.
    #
    # @return [Boolean]
    #   Specifies whether the changes were successfully pulled.
    #
    def pull(options={})
      arguments = []

      arguments << '-f' if options[:force]
      arguments << options[:repository] if options[:repository]

      git(:pull,*arguments)
    end

    #
    # Lists the commits in the Git repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [String] :commit
    #   Commit to start at.
    #
    # @option options [Symbol, String] :branch
    #   The branch to list commits within.
    #
    # @option options [Integer] :limit
    #   The number of commits to list.
    #
    # @option options [String, Array<String>] :paths
    #   The path(s) to list commits for.
    #
    # @yield [commit]
    #   The given block will be passed each commit.
    #
    # @yieldparam [Commits::Git] commit
    #   A commit from the repository.
    #
    # @return [Enumerator<Commits::Git>]
    #   The commits in the repository.
    #
    def commits(options={})
      return enum_for(:commits,options) unless block_given?

      arguments = ["--pretty=format:%H|%P|%T|%at|%an|%ae|%s"]

      if options[:limit]
        arguments << "-#{options[:limit]}"
      end

      if (options[:commit] || options[:branch])
        arguments << (options[:commit] || options[:branch])
      end

      if options[:paths]
        arguments += ['--', *options[:paths]]
      end

      commit  = nil
      parent  = nil
      tree    = nil
      date    = nil
      author  = nil
      email   = nil
      summary = nil

      popen('git log',*arguments) do |line|
        commit, parent, tree, date, author, email, summary = line.split('|',7)

        yield Commits::Git.new(
          commit,
          parent,
          tree,
          Time.at(date.to_i),
          author,
          email,
          summary
        )
      end
    end

    #
    # Lists the files of the Git repository.
    #
    # @param [String] pattern
    #   Optional glob pattern to filter the files by.
    #
    # @yield [file]
    #   The given block will be passed each file.
    #
    # @yieldparam [String] file
    #   A path of a file tracked by Git.
    #
    # @return [Enumerator]
    #   If no block is given, an Enumerator will be returned.
    #
    def files(pattern=nil,&block)
      return enum_for(:files,pattern) unless block

      arguments = []

      if pattern
        arguments << '--' << pattern
      end

      popen('git','ls-files',*arguments,&block)
      return nil
    end

    protected

    #
    # Runs a Git command.
    #
    # @param [Symbol] command
    #   The Git command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the Git command.
    #
    # @return [Boolean]
    #   Specifies whether the Git command exited successfully.
    #
    def git(command,*arguments)
      run(:git,command,*arguments)
    end

  end
end
