require 'scm/git'
require 'scm/hg'
require 'scm/svn'

module SCM
  # SCM control directories and the SCM classes
  DIRS = {
    '.git' => Git,
    '.hg' => Hg,
    '.svn' => SVN
  }

  URIS = {
    /^git:/ => Git,
    /^hg:/  => Hg,
    /^svn:/ => SVN,
    /.git$/ => Git,
    /.hg$/  => Hg,
    /.svn$/ => SVN
  }

  #
  # Determines the SCM used for a repository.
  #
  # @param [String] path
  #   The path of the repository.
  #
  # @return [Repository]
  #   The SCM repository.
  #
  # @raise [RuntimeError]
  #   The exact SCM could not be determined.
  #
  def SCM.new(path)
    path = File.expand_path(path)

    DIRS.each do |name,repo|
      dir = File.join(path,name)

      return repo.new(path) if File.directory?(dir)
    end

    raise("could not determine the SCM of #{path.dump}")
  end

  #
  # Determines the SCM used for a repository URI and clones it.
  #
  # @param [String] uri
  #   The URI to the repository.
  #
  # @return [Repository]
  #   The SCM repository.
  #
  # @raise [RuntimeError]
  #   The exact SCM could not be determined.
  #
  def SCM.clone(uri, opts={})
    URIS.each do |regex,repo|
      return repo.clone(uri, opts) if regex.match(uri)
    end

    raise("could not determine the SCM of #{uri.dump}")
  end
end
