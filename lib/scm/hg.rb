require 'scm/repository'

module SCM
  #
  # Interacts with Mercurial (Hg) repositories.
  #
  class Hg < Repository

    Commit = Struct.new :revision,
                        :hash    ,
                        :branch  ,
                        :user    ,
                        :date    ,
                        :summary 
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
    def add(*paths)
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
    def move(source,dest,force=false)
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
    def remove(paths,options={})
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
    def commit(message=nil,options={})
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
    # Deletes a branch.
    #
    # @param [String] name
    #   The name of the branch to delete.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully deleted.
    #
    def delete_branch(name)
      hg(:commit,'--close-branch','-m',"Closing #{name}")
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
    def tag(name,commit=nil)
      arguments = []

      if commit
        arguments << '-r' << commit
      end

      hg(:tag,name,*arguments)
    end

    #
    # Deletes a Hg tag.
    #
    # @param [String] name
    #   The name of the tag.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully deleted.
    #
    def delete_tag(name)
      hg(:tag,'--remove',name)
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

    #
    # Pushes changes to the remote Hg repository.
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
    #   Specifies whether the changes were successfully pushed.
    #
    def push(options={})
      arguments = []

      arguments << '-f' if options[:force]
      arguments << options[:repository] if options[:repository]

      hg(:push,*arguments)
    end

    #
    # Pulls changes from the remote Hg repository.
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

      hg(:pull,*arguments)
    end

    def commits
      commits = []
      commit  = Commit.new
      
      popen "hg log" do |line|
        case line
        when /changeset:\s+(\d+):(.+)/
          commit.revision = $1
          commit.hash = $2
        when /branch:\s+(.+)/
          commit.branch = $1
        when /user:\s+(.+)/
          commit.user = $1
        when /date:\s+(.+)/
          commit.date = Time.parse $1
        when /summary:\s+(.+)/
          commit.summary = $1
          commits.push commit
          commit = Commit.new
        end
      end

      commits
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
    def hg(command,*arguments)
      run(:hg,command,*arguments)
    end

  end
end
