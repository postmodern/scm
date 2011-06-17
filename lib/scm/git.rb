require 'scm/repository'

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
    def add!(*paths)
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
    def move!(source,dest,force=false)
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
    def remove!(paths,options={})
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
    def commit!(message=nil,options={})
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
    # @param [String] name
    #   The name of the branch to switch to.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    def switch_branch(name)
      git(:checkout,name)
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
    def tag!(name,commit=nil)
      arguments = []
      arguments << commit if commit

      git(:tag,name,*arguments)
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
