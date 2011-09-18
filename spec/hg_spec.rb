require 'spec_helper'
require 'scm/hg'

describe Hg do
  describe "create" do
    it "should create the directory, if it does not exist" do
      repo = Hg.create(directory('create_new_hg_repo'))

      repo.path.should be_directory
    end

    it "should create a hg repository" do
      repo = Hg.create(mkdir('init_hg_repo'))

      repo.path.join('.hg').should be_directory
    end
  end
end
