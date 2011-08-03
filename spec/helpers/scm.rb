require 'tmpdir'
require 'fileutils'

module Helpers
  module SCM
    ROOT_DIR = File.join(Dir.tmpdir,'scm')

    def directory(name)
      File.join(ROOT_DIR,name)
    end

    def mkdir(name)
      path = directory(name)

      FileUtils.mkdir_p(path)
      return path
    end
  end
end
