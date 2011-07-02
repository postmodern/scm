require 'scm/commits/commit'

module SCM
  module Commits
    #
    # Represents a commit in an {SCM::Hg Hg Repository}.
    #
    class Hg < Commit

      # The Hash of the commit
      attr_reader :hash

      # The branch of the commit
      attr_reader :branch

      #
      # Creates a new Hg commit.
      #
      # @param [String, Integer] revision
      #   The revision of the commit.
      #
      # @param [String] hash
      #   The hash of the commit.
      #
      # @param [String] branch
      #   The branch the commit belongs to.
      #
      # @param [String] user
      #   The Hg user that made the commit.
      #
      # @param [Time] date
      #   The date the commit was made on.
      #
      # @param [String] summary
      #   The summary of the commit.
      #
      def initialize(revision,hash,branch,user,date,summary)
        super(revision,date,user,summary)

        @hash = hash
        @branch = branch
      end

      alias revision commit
      alias user author

      #
      # Converts the commit to an Integer.
      #
      # @return [Integer]
      #   The commit revision.
      #
      def to_i
        @commit.to_i
      end

      #
      # Coerces the Hg commit into an Array.
      #
      # @return [Array<commit, hash, branch, date, author, summary>]
      #   The commit components.
      #
      def to_ary
        [@commit, @hash, @branch, @date, @user, @summary]
      end

    end
  end
end
