# encoding: utf-8

require 'yaml'

Gem::Specification.new do |gemspec|
  scm = if File.directory?('.git')
          :git
        end

  files = case scm
          when :git
            `git ls-files -z`.split("\0")
          else
            Dir.glob('{**/}{.*,*}').select { |path| File.file?(path) }
          end

  defaults = {
    :bin_files => 'bin/*',
    :files => 'lib/{**/}*.rb',
    :test_files => '{test/{**/}*_test.rb,spec/{**/}*_spec.rb}',
    :extra_doc_files => '*.{txt,rdoc,md,markdown,tt,textile}',
    :version_path => File.join('lib','scm','version.rb')
  }

  expand_files = lambda { |pattern|
    case pattern
    when Array
      pattern
    when String
      Dir.glob(pattern).select { |path|
        File.file?(path) && files.include?(path)
      }
    end
  }

  metadata = YAML.load_file('gemspec.yml')

  gemspec.name = if metadata['name']
                   metadata['name']
                 else
                   File.basename(File.dirname(__FILE__))
                 end

  gemspec.version = if metadata['version']
                      metadata['version']
                    elsif files.include?('VERSION')
                      File.read('VERSION').chomp
                    elsif files.include?(defaults[:version_path])
                      Kernel.load(defaults[:version_path])

                      SCM::VERSION
                    end

  gemspec.summary = metadata.fetch('summary',metadata['description'])
  gemspec.description = metadata.fetch('description',metadata['summary'])
  gemspec.licenses = metadata['license']

  gemspec.authors = metadata['authors']
  gemspec.email = metadata['email']
  gemspec.homepage = metadata['homepage']

  case metadata['require_paths']
  when Array
    gemspec.require_paths = metadata['require_paths']
  when String
    gemspec.require_path = metadata['require_paths']
  end

  gemspec.executables = if metadata['executables']
                          metadata['executables']
                        else
                          expand_files[defaults[:bin_files]].map { |path|
                            File.basename(path)
                          }
                        end

  if Gem::VERSION < '1.7.'
    gemspec.default_executable = if metadata['default_executable']
                                   metadata['default_executable']
                                 else
                                   gemspec.executables.first
                                 end
  end

  unless gemspec.files.include?('.document')
    gemspec.extra_rdoc_files = expand_files[defaults[:extra_doc_files]]
  end

  gemspec.files = if metadata['files']
                    expand_files[metadata['files']]
                  else
                    expand_files[defaults[:files]]
                  end

  gemspec.test_files = if metadata['test_files']
                         expand_files[metadata['test_files']]
                       else
                         expand_files[defaults[:test_files]]
                       end

  gemspec.post_install_message = metadata['post_install_message']
  gemspec.requirements = metadata['requirements']

  if gemspec.respond_to?(:required_ruby_version=)
    gemspec.required_ruby_version = metadata['required_ruby_version']
  end

  if gemspec.respond_to?(:required_rubygems_version=)
    gemspec.required_rubygems_version = metadata['required_ruby_version']
  end

  add_dependencies = lambda { |group|
    method = if group == :default
               'add_dependency'
             else
               if gemspec.respond_to?("add_#{group}_dependency")
                 "add_#{group}_dependency"
               else
                 'add_dependency'
               end
             end

    key = if group == :default
            'dependencies'
          else
            "#{group}_dependencies"
          end

    if metadata.has_key?(key)
      metadata[key].each do |name,versions|
        versions = case versions
                   when Array
                     versions.map { |v| v.to_s }
                   when String
                     versions.split(/,\s*/)
                   end

        gemspec.send(method,name.to_s,*versions)
      end
    end
  }

  add_dependencies[:default]
  add_dependencies['runtime']
  add_dependencies['development']
end
