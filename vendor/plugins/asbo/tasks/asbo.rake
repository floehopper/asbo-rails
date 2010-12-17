require 'rake'

require File.join(File.dirname(__FILE__), '..', 'lib', 'asbo')

Asbo::TEST_TASKS.each do |name|
  task(name).enhance do
    Asbo::tests_passed(name)
  end
end
