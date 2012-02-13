require 'scm/git'
require 'scm/hg'
require 'scm/svn'

require 'uri'

module SCM
  # SCM control directories and the SCM classes
  DIRS = {
    '.git' => Git,
    '.hg' => Hg,
    '.svn' => SVN
  }

  # Common URI schemes used to denote the SCM
  SCHEMES = {
    'git' => Git,
    'hg'  => Hg,
    'svn' => SVN
  }

  # Common file extensions used to denote the SCM of a URI
  EXTENSIONS = {
    '.git' => Git,
    '.hg'  => Hg,
    '.svn' => SVN
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
  # @raise [ArgumentError]
  #   The exact SCM could not be determined.
  #
  def SCM.new(path)
    path = File.expand_path(path)

    DIRS.each do |name,repo|
      dir = File.join(path,name)

      return repo.new(path) if File.directory?(dir)
    end

    raise(ArgumentError,"could not determine the SCM of #{path.dump}")
  end

  #
  # Determines the SCM used for a repository URI and clones it.
  #
  # @param [URI, String] uri
  #   The URI to the repository.
  #
  # @param [Hash] options
  #   Additional SCM specific clone options.
  #
  # @return [Repository]
  #   The SCM repository.
  #
  # @raise [ArgumentError]
  #   The exact SCM could not be determined.
  #
  def SCM.clone(uri,options={})
    uri = URI(uri) unless uri.kind_of?(URI)
    scm = (SCHEMES[uri.scheme] || EXTENSIONS[File.extname(uri.path)])

    unless scm
      raise(ArgumentError,"could not determine the SCM of #{uri}")
    end

    return scm.clone(uri,options)
  end
end
