require 'spec_helper'
require 'scm/git'

describe Git do
  describe "create" do
    it "should create the directory, if it does not exist" do
      repo = Git.create(directory('create_new_git_repo'))

      repo.path.should be_directory
    end

    it "should create a git repository" do
      repo = Git.create(mkdir('init_git_repo'))

      repo.path.join('.git').should be_directory
    end

    it "should allow creating a bare git repository" do
      repo = Git.create(mkdir('init_bare_git_repo'))

      repo.path.entries.map(&:to_s).should be =~ %w[
        branches  config  description  HEAD  hooks  info  objects  refs
      ]
    end
  end
end
