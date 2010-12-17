require 'rexml/document'
require 'digest/md5'
require 'yaml'
require 'optparse'

module Asbo
  
  TEST_TASKS = %w(test:units test:functionals test:integration)
  
  class << self
    
    def tests_passed(task_name)
      abort "Warning: No test task name specified" if task_name.empty?
      FileUtils.mkdir_p(File.join('tmp', 'asbo'))
      data = { 'svn_base_revision' => Asbo::svn_base_revision, 'svn_diff_md5' => Asbo::svn_diff_md5 }
      filename = File.join('tmp', 'asbo', "#{task_name.gsub(/:/, '-')}.yml")
      File.open(filename, 'w') { |file| file.puts(data.to_yaml) }
    end
    
    def svn_base_revision
      svn_log = `svn log --revision BASE --xml`
      abort "Warning: unable to execute 'svn log'." unless $?.success?
      document = REXML::Document.new(svn_log)
      Integer(document.elements['/log/logentry'].attributes['revision'])
    end
    
    def svn_diff_md5
      svn_diff = `svn diff`
      abort "Warning: unable to execute 'svn diff'." unless $?.success?
      Digest::MD5.hexdigest(svn_diff)
    end
    
    def pre_commit
      errors = []
      svn_base_revision_check(errors)
      svn_diff_md5_check(errors)
      abort errors.join("\n") unless errors.empty?
    end
    
    def commit
      options = {}
      OptionParser.new do |opts|
        opts.on("-m arg", "--message arg", "specify log message ARG") do |m|
          options[:message] = m
        end
      end.parse!
      
      words = %w(svn commit)
      words += options.map { |option, value| "--#{option} \"#{value}\"" }
      words += ARGV
      command = words.join(" ")
      
      `#{command}`
      abort "Warning: unable to execute '#{command}'." unless $?.success?
    end
    
    def post_commit
      Dir.glob(File.join('tmp', 'asbo', '*.yml')).each do |filename|
        working_set = YAML.load(File.open(filename))
        working_set['svn_diff_md5'] = Asbo::svn_diff_md5
        File.open(filename, 'w') { |file| file.puts(working_set.to_yaml) }
      end
    end
    
    private
    
    def svn_base_revision_check(errors)
      current_svn_base_revision = svn_base_revision
      TEST_TASKS.each do |task_name|
        filename = File.join('tmp', 'asbo', "#{task_name.gsub(/:/, '-')}.yml")
        stored_svn_base_revision = YAML.load(File.open(filename))['svn_base_revision'] rescue nil
        unless stored_svn_base_revision == current_svn_base_revision
          errors << "#{task_name} has not been run successfully since the last svn update."
        end
      end
    end
    
    def svn_diff_md5_check(errors)
      current_svn_diff_md5 = svn_diff_md5
      TEST_TASKS.each do |task_name|
        filename = File.join('tmp', 'asbo', "#{task_name.gsub(/:/, '-')}.yml")
        stored_svn_diff_md5 = YAML.load(File.open(filename))['svn_diff_md5'] rescue nil
        unless stored_svn_diff_md5 == current_svn_diff_md5
          errors << "#{task_name} has not been run successfully since the last local modification."
        end
      end
    end
    
  end

end
