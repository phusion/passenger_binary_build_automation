#!/usr/bin/env ruby
# Usage: copy-dir.rb <INPUT> <OUTPUT>
# Copies a directory to a different place, respecting gitignore rules.

require 'fileutils'
require 'open3'
require 'pathname'
require 'tmpdir'

TIMESTAMP = Time.utc(2024, 10, 11, 0, 0, 0)

class CopyError < StandardError; end

def main(args)
  if args.length != 2
    puts "Usage: #{$PROGRAM_NAME} <INPUT> <OUTPUT>"
    puts "Copies a directory to a different place, respecting gitignore rules."
    exit 1
  end

  input_dir = Pathname.new(args[0]).expand_path
  output_dir = Pathname.new(args[1]).expand_path

  begin
    files = git_ls_files(input_dir)
  rescue Interrupt
    exit 1
  rescue => e
    abort "Error listing files in #{input_dir}: #{e}"
  end

  begin
    copy_files(input_dir, output_dir, files, timestamp: TIMESTAMP)
  rescue CopyError => e
    abort(e.to_s)
  rescue Interrupt
    exit 1
  end
end

def git_ls_files(dir)
  files = []

  if File.directory?(dir / '.git')
    files.concat(
      run_command("git", "-C", dir.to_s, "ls-files", "--cached", "--others", "--exclude-standard")
    )
    list_git_submodules(dir).each do |relative_submodule_path|
      submodule_dir = dir / relative_submodule_path
      files.concat(git_ls_files(submodule_dir).map { |path| File.join(relative_submodule_path, path) })
    end
  else
    Dir.mktmpdir do |git_dir|
      run_command("git", "--git-dir=#{git_dir}", "--work-tree=#{dir}", "init", "-q")
      files.concat(
        run_command("git", "--git-dir=#{git_dir}", "--work-tree=#{dir}", "ls-files", "--others", "--exclude-standard")
      )
    end
  end

  files.reject! { |path| !File.exist?(dir / path) || File.directory?(dir / path) }
  files
end

def list_git_submodules(dir)
  run_command("git", "-C", dir.to_s, "submodule", "foreach", "--quiet", 'echo "$sm_path"')
end

def copy_files(input_dir, output_dir, paths, timestamp:)
  FileUtils.mkdir_p(output_dir)
  paths.each do |path|
    src = input_dir / path
    dst = output_dir / path
    FileUtils.mkdir_p(dst.dirname)

    begin
      FileUtils.cp(src, dst)
    rescue => e
      raise CopyError, "Error copying #{src} to #{dst}: #{e}"
    end

    begin
      File.utime(timestamp, timestamp, dst)
    rescue => e
      raise CopyError, "Error setting timestamp for #{dst}: #{e}"
    end
  end
end

def run_command(*args)
  output, status = Open3.capture2(*args)
  raise "Command failed: #{args.join(' ')}" unless status.success?
  output.split("\n")
end

main(ARGV)
