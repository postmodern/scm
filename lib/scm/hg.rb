require 'scm/repository'
require 'scm/commits/hg'

require 'uri'

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
    # Creates a Hg repository.
    #
    # @param [String] path
    #   The path to the repository.
    #
    # @return [Hg, URI::Generic]
    #   The initialized local Hg repository or the URI to the remote
    #   repository.
    #
    # @raise [RuntimeError]
    #   Could not initialize the Hg repository.
    #
    def self.create(path,options={})
      if options[:bare]
        raise("Hg does not support creating bare repositories")
      end

      unless path.start_with?('ssh://')
        FileUtils.mkdir_p(path)
      end

      arguments = [path]

      unless (result = run('init',arguments,options))
        raise("unable to initialize Hg repository #{path.dump}")
      end

      if path.start_with?('ssh://')
        return URI(path)
      else
        return new(path)
      end
    end

    #
    # Clones a remote Hg repository.
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

      if (commits = options.delete(:commits))
        arguments << '--rev' << commits
      end

      if (branch = options.delete(:branch))
        arguments << '--branch' << branch
      end

      arguments << uri

      if (dest = options.delete(:dest))
        arguments << dest
      end

      return run('clone',arguments,options)
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

      popen('status',*paths) do |line|
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
      run('add',*paths)
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

      return run('mv',*arguments)
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
    #   {#remove} does not respond to the `:recursive` option.
    #   Hg removes directories recursively by default.
    #
    def remove(paths,options={})
      arguments = []

      arguments << '--force' if options[:force]
      arguments += ['--', *paths]

      return run('rm',*arguments)
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

      return run('commit',*arguments)
    end

    #
    # Lists branches in the SVN repository.
    #
    # @return [Array<String>]
    #   The branch names.
    #
    def branches
      branches = []

      popen('branches') do |line|
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
      popen('branch').chomp
    end

    #
    # Swtiches to another Hg branch.
    #
    # @param [String, Symbol] name
    #   The name of the branch to switch to.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    def switch_branch(name)
      run('update',name)
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
      run('commit','--close-branch','-m',"Closing #{name}")
    end

    #
    # Lists Hg tags.
    #
    # @return [Array<String>]
    #   The tag names.
    #
    def tags
      tags = []

      popen('tags') do |line|
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

      return run('tag',name,*arguments)
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
      run('tag','--remove',name)
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

      return run('log',*arguments)
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

      return run('push',*arguments)
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

      return run('pull',*arguments)
    end

    #
    # Lists the commits in the Hg repository.
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
    # @yieldparam [Commits::Hg] commit
    #   A commit from the repository.
    #
    # @return [Enumerator<Commits::Hg>]
    #   The commits in the repository.
    #
    def commits(options={})
      return enum_for(:commits,options) unless block_given?

      arguments = ['-v']

      if options[:commit]
        arguments << '--rev' << options[:commit]
      end

      if options[:branch]
        arguments << '--branch' << options[:branch]
      end

      if options[:limit]
        arguments << '--limit' << options[:limit]
      end

      if options[:paths]
        arguments.push(*options[:paths])
      end
      
      revision = nil
      hash     = nil
      branch   = nil
      user     = nil
      date     = nil
      summary  = nil
      message  = nil
      files    = nil

      io = popen('log',*arguments)

      until io.eof?
        line = io.readline.chomp

        if line.empty?
          yield Commits::Hg.new(revision,hash,branch,user,date,summary,message,files)

          revision = hash = branch = user = date = summary = message = files = nil
        else
          key, value = line.split(' ',2)

          case key
          when 'changeset:'
            revision, hash = value.split(':',2)
          when 'branch:'
            branch = value
          when 'user:'
            user = value
          when 'date:'
            date = Time.parse(value)
          when 'description:'
            description = readlines_until(io)
            summary     = description[0]
            message     = description.join($/)
          when 'files:'
            files = value.split(' ')
          end
        end
      end
    end

    #
    # Lists the files of the Hg repository.
    #
    # @yield [file]
    #   The given block will be passed each file.
    #
    # @yieldparam [String] file
    #   A path of a file tracked by Hg.
    #
    # @return [Enumerator]
    #   If no block is given, an Enumerator will be returned.
    #
    def files(&block)
      return enum_for(:files) unless block

      popen('manifest',&block)
      return nil
    end

  end
end
