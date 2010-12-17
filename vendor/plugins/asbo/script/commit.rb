#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), '..', 'lib', 'asbo')

Asbo::pre_commit
Asbo::commit
Asbo::post_commit