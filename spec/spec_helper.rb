require 'rspec'
require 'helpers/scm'

require 'scm/version'
include SCM

RSpec.configure do |rspec|
  rspec.include Helpers::SCM

  rspec.after(:suite) do
    FileUtils.rm_rf(Helpers::SCM::ROOT_DIR)
  end
end
