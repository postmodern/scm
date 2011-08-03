require 'scm/repository'
require 'scm/commits/svn'

module SCM
  #
  # Interacts with SubVersion (SVN) repositories.
  #
  class SVN < Repository

    # SVN status codes displayed in the First Column
    STATUSES = {
      'A' => :added,
      'C' => :conflicted,
      'D' => :deleted,
      'I' => :ignored,
      'M' => :modified,
      'R' => :replaced,
      'X' => :unversioned,
      '?' => :untracked,
      '!' => :missing,
      '~' => :obstructed
    }

    LOG_SEPARATOR = '------------------------------------------------------------------------'

    #
    # Initializes the SVN repository.
    #
    # @param [String] path
    #   The path to the SVN repository.
    #
    def initialize(path)
      path = File.expand_path(path)

      super(path)

      @root = if File.basename(@path) == 'trunk'
                File.dirname(@path)
              else
                @path
              end

      @trunk = File.join(@root,'trunk')
      @branches = File.join(@root,'branches')
      @tags = File.join(@root,'tags')
    end

    #
    # Creates an SVN repository.
    #
    # @param [String] path
    #   The path to the repository.
    #
    # @return [SVN]
    #   The new SVN repository.
    #
    # @raise [RuntimeError]
    #
    def self.create(path,options={})
      path = File.expand_path(path)

      unless system('svnadmin','create',path)
        raise("could not create SVN repository #{path.dump}")
      end

      return new(path)
    end

    #
    # Checks out a remote SVN repository.
    #
    # @param [URI, String] uri
    #   The URI of the remote repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [String, Integer] :commits
    #   The commits to include.
    #
    # @option options [String] :dest
    #   The destination directory to clone into.
    #
    # @return [Boolean]
    #   Specifies whether the clone was successful.
    #
    def self.checkout(uri,options={})
      arguments = []

      if options[:commits]
        arguments << '--revision' << options[:commits]
      end

      arguments << uri
      arguments << options[:dest] if options[:dest]

      system('svn','checkout',*arguments)
    end

    #
    # @see checkout
    #
    def self.clone(uri,options={})
      checkout(uri,options)
    end

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

      popen('svn status',*paths) do |line|
        status = line[0,1]
        path = line[8..-1]

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
      svn(:add,*paths)
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
    #   SVN removes directories recursively by default.
    #
    def remove(paths,options={})
      arguments = []

      arguments << '--force' if options[:force]
      arguments += ['--', *paths]

      svn(:rm,*arguments)
    end

    #
    # Makes a SVN commit.
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

      svn(:commit,*arguments)
    end

    #
    # Lists branches in the SVN repository.
    #
    # @return [Array<String>]
    #   The branch names.
    #
    def branches
      branches = []

      Dir.glob(File.join(@branches,'*')) do |path|
        branches << File.basename(path) if File.directory(path)
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
      if @path == @trunk
        'trunk'
      else
        File.basename(@path)
      end
    end

    #
    # Swtiches to another SVN branch.
    #
    # @param [String, Symbol] name
    #   The name of the branch to switch to.
    #   The name may also be `trunk`, to switch back to the `trunk`
    #   directory.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    def switch_branch(name)
      name = name.to_s
      branch_dir = if name == 'trunk'
                     @trunk
                   else
                     File.join(@branches,name)
                   end

      if File.directory?(branch_dir)
        @path = branch_dir
        return true
      else
        return false
      end
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
      branch_dir = File.join(@branchs,name)

      return false unless File.directory?(branch_dir)

      svn(:rm,File.join('..','branchs',name))
    end

    #
    # Lists tags in the SVN repository.
    #
    # @return [Array<String>]
    #   The tag names.
    #
    def tags
      tags = []

      Dir.glob(File.join(@tags,'*')) do |path|
        tags << File.basename(path) if File.directory(path)
      end

      return tags
    end

    #
    # Creates a SVN tag.
    #
    # @param [String] name
    #   The name for the tag.
    #
    # @param [String] commit
    #   The commit argument is not supported by {SVN}.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully created.
    #
    # @raise [ArgumentError
    #   The `commit` argument was specified.
    #
    def tag(name,commit=nil)
      if commit
        raise(ArgumentError,"the commit argument is not supported by #{SVN}")
      end

      return false unless File.directory?(@trunk)

      File.mkdir(@tags) unless File.directory?(@tags)

      svn(:cp,@trunk,File.join(@tags,name))
    end

    #
    # Deletes a SVN tag.
    #
    # @param [String] name
    #   The name of the tag.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully deleted.
    #
    def delete_tag(name)
      tag_dir = File.join(@tags,name)

      return false unless File.directory?(tag_dir)

      svn(:rm,tag_dir)
    end

    #
    # Prints a SVN log.
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
        arguments << '-c' << options[:commit]
      end
      
      if options[:paths]
        arguments += [*options[:paths]]
      end

      svn(:log,*arguments)
    end

    #
    # @return [true]
    #
    # @note no-op
    #
    def push(options={})
      true
    end

    #
    # Pulls changes from the remote SVN repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @option options [Boolean] :force
    #   Specifies whether to force pushing the changes.
    #
    # @return [Boolean]
    #   Specifies whether the changes were successfully pulled.
    #
    def pull(options={})
      arguments = []
      arguments << '-f' if options[:force]

      svn(:update,*arguments)
    end

    #
    # Lists the commits in the SVN repository.
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
    # @yieldparam [Commits::SVN] commit
    #   A commit from the repository.
    #
    # @return [Enumerator<Commits::SVN>]
    #   The commits in the repository.
    #
    def commits(options={})
      return enum_for(:commits,options) unless block_given?

      arguments = []

      if options[:commit]
        arguments << '--revision' << options[:commit]
      end

      if options[:limit]
        arguments << '--limit' << options[:limit]
      end

      if options[:paths]
        arguments.push(*options[:paths])
      end

      revision = nil
      date     = nil
      author   = nil
      summary  = ''

      io = popen('svn log',*arguments)

      # eat the first LOG_SEPARATOR
      io.readline

      until io.eof?
        line = io.readline
        line.chomp!

        revision, author, date, changes = line.split(' | ',4)
        revision = revision[1..-1].to_i
        date = Time.parse(date)

        # eat the empty line separating the metadata from the summary
        line.readline

        loop do
          line = io.readline
          break if line == LOG_SEPARATOR

          summary << line
        end

        yield Commits::SVN.new(revision,date,author,summary)

        revision = date = author = nil
        summary = ''
      end
    end

    protected

    #
    # Runs a SVN command.
    #
    # @param [Symbol] command
    #   The SVN command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the SVN command.
    #
    # @return [Boolean]
    #   Specifies whether the SVN command exited successfully.
    #
    def svn(command,*arguments)
      run(:svn,command,*arguments)
    end

  end
end
