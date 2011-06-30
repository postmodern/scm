require 'scm/util'

module SCM
  class Repository

    include Util

    # The path of the repository
    attr_reader :path

    #
    # Creates a new repository.
    #
    # @param [String] path
    #   The path to the repository.
    #
    def initialize(path)
      @path = File.expand_path(path)
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
    # @param [String] name
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
    # Converts the repository to a String.
    #
    # @return [String]
    #   The path of the repository.
    #
    def to_s
      @path.to_s
    end

    protected

    #
    # Runs a command within the repository.
    #
    # @param [Symbol] command
    #   The command to run.
    #
    # @param [Array] arguments
    #   Additional arguments to pass to the command.
    #
    # @return [Boolean]
    #   Specifies whether the SVN command exited successfully.
    #
    def run(command,*arguments)
      Dir.chdir(@path) { super(command,*arguments) }
    end

    #
    # Runs a command as a separate process.
    #
    # @param [Symbol] command
    #   The command to run.
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
    def popen(command,*arguments)
      Dir.chdir(@path) { super(command,*arguments) }
    end

  end
end
