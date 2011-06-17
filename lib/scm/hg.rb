require 'scm/repository'

module SCM
  #
  # Interacts with Mercurial (Hg) repositories.
  #
  class Hg < Repository

    # Hg status codes
    STATUSES = {
      'M' => :modified,
      'A' => :added,
      'R' => :removed,
      'C' => :clean,
      '!' => :missing,
      '?' => :untracked,
      'I' => :ignored,
      ' ' => :origin
    }

    #
    # Queries the status of the repository.
    #
    # @param [Array] paths
    #   Optional paths to query the statuses of.
    #
    # @return [Hash{String => Symbol}]
    #   The paths and their repsective statuses.
    #
    def status(*paths)
      statuses = {}

      popen('hg status',*paths) do |line|
        status, path = line.split(' ',2)

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
      hg(:add,*paths)
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

      arguments << '--force' if force
      arguments << source << dest

      svn(:mv,*arguments)
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
    # @note
    #   {#remove!} does not respond to the `:recursive` option.
    #   Hg removes directories recursively by default.
    #
    def remove!(paths,options={})
      arguments = []

      arguments << '--force' if options[:force]
      arguments += ['--', *paths]

      hg(:rm,*arguments)
    end

    #
    # Makes a Hg commit.
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
        arguments += [*options[:paths]]
      end

      hg(:commit,*arguments)
    end

    #
    # Lists branches in the SVN repository.
    #
    # @return [Array<String>]
    #   The branch names.
    #
    def branches
      branches = []

      popen('hg branches') do |line|
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
    def branch
      popen('hg branch').chomp
    end

    #
    # Swtiches to another Hg branch.
    #
    # @param [String] name
    #   The name of the branch to switch to.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    def switch_branch(name)
      hg(:update,name)
    end

    #
    # Lists Hg tags.
    #
    # @return [Array<String>]
    #   The tag names.
    #
    def tags
      tags = []

      popen('hg tags') do |line|
        tags << line[2..-1]
      end

      return tags
    end

    #
    # Creates a Hg tag.
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

      if commit
        arguments << '-r' << commit
      end

      hg(:tag,name,*arguments)
    end

    #
    # Prints the Hg log.
    #
    # @param [String] :commit
    #   Commit to begin the log at.
    #
    # @param [String] :paths
    #   File to list commits for.
    #
    def log(options={})
      arguments = []

      if options[:commit]
        arguments << '-r' << options[:commit]
      end
      
      if options[:paths]
        arguments += [*options[:paths]]
      end

      hg(:log,*arguments)
    end

    protected

    #
    # Runs a Hg command.
    #
    # @param [Symbol] command
    #   The Hg command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the Hg command.
    #
    # @return [Boolean]
    #   Specifies whether the Hg command exited successfully.
    #
    def svn(command,*arguments)
      run(:hg,command,*arguments)
    end

  end
end
