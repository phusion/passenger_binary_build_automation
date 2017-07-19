#!/usr/bin/env ruby
require 'fileutils'

FROM = ARGV[0]
TO = ARGV[1]
if ARGV[2] == '--exclude'
  EXCLUSIONS = ARGV[3..-1]
end

files = Dir.glob("#{FROM}/*", File::FNM_DOTMATCH)
files.delete("#{FROM}/.")
files.delete("#{FROM}/..")
files.delete("#{FROM}/.git")
files.delete("#{FROM}/.bundle")
files.delete("#{FROM}/.vagrant")

if defined?(EXCLUSIONS)
  EXCLUSIONS.each do |exclusion|
    files.delete("#{FROM}/#{exclusion}")
  end
end

FileUtils.mkdir_p(TO)
FileUtils.cp_r(files, "#{TO}/")
