require 'scm/commits/commit'

module SCM
  module Commits
    class Git < Commit

      # The parent of the commit
      attr_reader :parent

      # The tree of the commit
      attr_reader :tree

      # The email of the author
      attr_reader :email

      #
      # Creates a new Git commit.
      #
      # @param [String] commit
      #   The SHA1 hash of the commit.
      #
      # @param [String] parent
      #   The SHA1 hash of the parent commit.
      #
      # @param [String] tree
      #   The SHA1 hash of the tree.
      #
      # @param [Time] date
      #   The date the commit was made.
      #
      # @param [String] author
      #   The author of the commit.
      #
      # @param [String] email
      #   The email for the author.
      #
      # @param [String] summary
      #   The summary of the commit.
      #
      def initialize(commit,parent,tree,date,author,email,summary,message,files)
        super(commit,date,author,summary,message,files)

        @parent = parent
        @tree   = tree
        @email  = email
      end

      alias sha1 commit

      #
      # Coerces the Git commit into an Array.
      #
      # @return [Array<commit, parent, tree, date, author, email, summary, message, files>]
      #   The commit components.
      #
      def to_ary
        [@commit, @parent, @tree, @date, @author, @email, @summary, @message, @files]
      end

    end
  end
end
