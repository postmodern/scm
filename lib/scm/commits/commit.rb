require 'time'

module SCM
  module Commits
    #
    # Base-class for other SCM Commit classes.
    #
    class Commit

      # The commit hash or revision number
      attr_reader :commit

      # The date of the commit
      attr_reader :date

      # The author of the commit
      attr_reader :author

      # The summary of the commit
      attr_reader :summary

      # The full commit message of the commit
      attr_reader :message

      # The files changed by the commit
      attr_reader :files

      #
      # Creates a new commit object.
      #
      # @param [String, Integer] commit
      #   The commit hash or revision number.
      #
      # @param [Time] date
      #   The date of the commit.
      #
      # @param [String] author
      #   The author of the commit.
      #
      # @param [String] summary
      #   The summary of the commit.
      #
      # @param [String] message
      #   The full commit message of the commit.
      #
      # @param [String] files
      #   The files changed in the commit.
      #
      def initialize(commit,date,author,summary,message,files=[])
        @commit  = commit
        @date    = date
        @author  = author
        @summary = summary
        @message = message
        @files   = files
      end

      #
      # Inspects the commit.
      #
      # @return [String]
      #   The inspected commit.
      #
      def inspect
        "#<#{self.class}: #{@commit}>"
      end

      #
      # Converts the commit to a String.
      #
      # @return [String]
      #   The commit hash or revision.
      #
      def to_s
        @commit.to_s
      end

      #
      # Coerces the commit into an Array.
      #
      # @return [Array<commit, date, author, summary>]
      #   The commit components.
      #
      def to_ary
        [@commit, @date, @author, @summary]
      end

    end
  end
end
