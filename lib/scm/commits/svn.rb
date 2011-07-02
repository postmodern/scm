require 'scm/commits/commit'

module SCM
  module Commits
    class SVN < Commit

      alias revision commit
      alias user author

    end
  end
end
