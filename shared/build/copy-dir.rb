#!/usr/bin/env ruby
require 'fileutils'

FROM = ARGV[0]
TO = ARGV[1]

files = Dir.glob("#{FROM}/*", File::FNM_DOTMATCH)
files.delete("#{FROM}/.")
files.delete("#{FROM}/..")
files.delete("#{FROM}/.git")
files.delete("#{FROM}/.vagrant")

FileUtils.cp_r(files, "#{TO}/")
