require 'scm/util'

require 'pathname'

module SCM
  class Repository

    # The path of the repository
    attr_reader :path

    # SCM specification options for the repository
    attr_reader :options

    #
    # Creates a new repository.
    #
    # @param [String] path
    #   The path to the repository.
    #
    # @param [Hash] options
    #   SCM specific options for the repository.
    #
    def initialize(path,options={})
      @path    = Pathname.new(File.expand_path(path))
      @options = options
    end

    #
    # The path to the SCM binary.
    #
    # @return [String, nil]
    #   The binary path.
    #
    def self.path
      @path ||= nil
    end

    #
    # Sets the path to the SCM binary.
    #
    # @param [String, nil] new_path
    #   The new path to the SCM binary.
    #
    # @return [String, nil]
    #   The new SCM binary path.
    #
    def self.path=(new_path)
      @path = if new_path
                 File.expand_path(new_path)
               end
    end

    #
    # Creates a new repository.
    #
    # @param [String] path
    #   Path to the repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Repository]
    #   The newly created repository.
    #
    # @abstract
    #
    def self.create(path,options={})
      new(path,options)
    end

    #
    # Clones a remote repository.
    #
    # @param [URI, String] uri
    #   The URI of the remote repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Boolean]
    #   Specifies whether the clone was successful.
    #
    # @abstract
    #
    def self.clone(uri,options={})
      false
    end

    #
    # Queries the status of the files.
    #
    # @param [Array] paths
    #   The optional paths to query.
    #
    # @return [Hash{String => Symbol}]
    #   The file paths and their statuses.
    #
    # @abstract
    #
    def status(*paths)
      {}
    end

    #
    # Adds files or directories to the repository.
    #
    # @param [Array] paths
    #   The paths of the files/directories to add.
    #
    # @abstract
    #
    def add(*paths)
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
    # @abstract
    #
    def move(source,dest,force=false)
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
    # @abstract
    #
    def remove(paths,options={})
    end

    #
    # Makes a commit.
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
    # @abstract
    #
    def commit(message=nil,options={})
      false
    end

    #
    # Lists branches.
    #
    # @return [Array<String>]
    #   The branch names.
    #
    # @abstract
    #
    def branches
      []
    end

    #
    # The current branch.
    #
    # @return [String]
    #   The name of the current branch.
    #
    # @abstract
    #
    def current_branch
    end

    #
    # Swtiches to a branch.
    #
    # @param [String, Symbol] name
    #   The name of the branch to switch to.
    #
    # @return [Boolean]
    #   Specifies whether the branch was successfully switched.
    #
    # @abstract
    #
    def switch_branch(name)
      false
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
    # @abstract
    #
    def delete_branch(name)
      false
    end

    #
    # Lists tags.
    #
    # @return [Array<String>]
    #   The tag names.
    #
    # @abstract
    #
    def tags
      []
    end

    #
    # Tags a release.
    #
    # @param [String] name
    #   The name for the tag.
    #
    # @param [String] commit
    #   The specific commit to make the tag at.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully created.
    #
    # @abstract
    #
    def tag(name,commit=nil)
      false
    end

    #
    # Deletes a tag.
    #
    # @param [String] name
    #   The name of the tag.
    #
    # @return [Boolean]
    #   Specifies whether the tag was successfully deleted.
    #
    # @abstract
    #
    def delete_tag(name)
      false
    end

    #
    # Prints a log of commits.
    #
    # @param [String] :commit
    #   Commit to begin the log at.
    #
    # @param [String] :paths
    #   File to list commits for.
    #
    # @abstract
    #
    def log(options={})
      false
    end

    #
    # Pushes changes to the remote repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Boolean]
    #   Specifies whether the changes were successfully pushed.
    #
    # @abstract
    #
    def push(options={})
      false
    end

    #
    # Pulls changes from the remote repository.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Boolean]
    #   Specifies whether the changes were successfully pulled.
    #
    # @abstract
    #
    def pull(options={})
      false
    end

    #
    # Lists commits.
    #
    # @param [Hash] options
    #   Additional options.
    #
    # @return [Enumerator<SCM::Commit>] 
    #   The commits within the repository.
    #
    # @raise  [NotImplementedError]
    #   If a subclass does not provide its own implementation.
    #
    # @abstract
    #
    def commits(options={})
      raise(NotImplementedError,"This method is not implemented for #{self.class}")
    end

    #
    # Converts the repository to a String.
    #
    # @return [String]
    #   The path of the repository.
    #
    def to_s
      @path.to_s
    end

    #
    # Inspects the Repository.
    #
    # @return [String]
    #   The repository class name and path.
    #
    def inspect
      "#<#{self.class}: #{@path}>"
    end

    #
    # Lists the files of the repository.
    #
    # @yield [file]
    #   The given block will be passed each file.
    #
    # @yieldparam [String] file
    #   A path of a file within the repository.
    #
    # @return [Enumerator]
    #   If no block is given, an Enumerator will be returned.
    #
    # @abstract
    #
    def files(&block)
    end

    protected

    extend Util

    #
    # Formats SCM specific options.
    #
    # @param [Hash] options
    #   The SCM specific options to format.
    #
    # @return [Array<String>]
    #   SCM specific arguments.
    #
    # @abstract
    #
    def self.options(options)
      []
    end

    #
    # Builds a command for the SCM executable.
    #
    # @param [String] sub_command
    #   The SCM sub-command to invoke.
    #
    # @param [Array<String>] arguments
    #   Additional arguments for the command.
    #
    # @return [Array<String>]
    #   The arguments for the SCM command.
    #
    def self.command(sub_command,arguments,options=nil)
      program = (path || self.name.split('::').last.downcase)

      if options
        arguments = self.options(options) + arguments
      end

      return [program, sub_command] + arguments
    end

    #
    # Runs a sub-command of the SCM.
    #
    # @param [String] sub_command
    #   The name of the SCM sub_command to run.
    #
    # @param [Array<String>] arguments
    #   Additional arguments for the sub-command.
    #
    # @param [Hash] options
    #   Additional SCM options.
    #
    # @see Util#run
    #
    def self.run(sub_command,arguments,options=nil)
      super(*command(sub_command,arguments,options))
    end

    #
    # Runs a sub-command of the SCM.
    #
    # @param [String] sub_command
    #   The name of the SCM sub_command to run.
    #
    # @param [Array<String>] arguments
    #   Additional arguments for the sub-command.
    #
    # @param [Hash] options
    #   Additional SCM options.
    #
    # @see Util#popen
    #
    def self.popen(sub_command,arguments,options=nil,&block)
      super(*command(sub_command,arguments,options),&block)
    end

    #
    # Runs a command within the repository.
    #
    # @param [Symbol] sub_command
    #   The SCM sub-command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the command.
    #
    # @return [Boolean]
    #   Specifies whether the SVN command exited successfully.
    #
    def run(sub_command,*arguments)
      Dir.chdir(@path) { self.class.run(sub_command,arguments,@options) }
    end

    #
    # Runs a command as a separate process.
    #
    # @param [Symbol] sub_command
    #   The sub-command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the command.
    #
    # @yield [line]
    #   The given block will be passed each line read-in.
    #
    # @yieldparam [String] line
    #   A line read from the program.
    #
    # @return [IO]
    #   The stdout of the command being ran.
    #
    def popen(sub_command,*arguments,&block)
      Dir.chdir(@path) do
        self.class.popen(sub_command,arguments,@options,&block)
      end
    end

  end
end
