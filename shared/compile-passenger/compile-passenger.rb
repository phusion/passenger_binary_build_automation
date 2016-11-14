#!/usr/bin/env ruby
# encoding: utf-8

SELFDIR = File.absolute_path(File.dirname(__FILE__))
ROOT = File.absolute_path(SELFDIR + '/../..')

require 'optparse'
require 'logger'
require 'fileutils'
require 'shellwords'
require_relative '../lib/library'

class CompilePassenger
  include FileUtils
  include Library

  RUBY_VERSIONS = File.read("#{ROOT}/shared/definitions/ruby_versions").split
  DEFAULT_RUBY_VERSION = RUBY_VERSIONS.last

  def start
    parse_options
    set_environment
    initialize_logger
    copy_codebase
    compile
    commit_output
  end

private
  def parse_options
    @options = { concurrency: 2 }

    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: ./compile-passenger.rb OPTIONS'
      opts.separator ''

      opts.separator 'Options:'
      opts.on('--passenger-dir DIR', String, 'The directory in which the Passenger source code is located') do |val|
        @options[:passenger_dir] = File.expand_path(val)
      end
      opts.on('--output-dir DIR', String, 'The directory in which to store binaries') do |val|
        @options[:output_dir] = File.expand_path(val)
      end
      opts.on('--concurrency NUMBER', Integer, 'The number of compilation jobs to run concurrently. Default: 2') do |val|
        @options[:concurrency] = val
      end
      opts.on('--inside-holy-build-box', 'Signal that we are running inside Holy Build Box') do
        @options[:holy_build_box] = true
      end
      opts.on('--timeout TIMEOUT', Integer, 'Timeout in seconds') do |val|
        @options[:timeout] = val
      end
      opts.on('--help', '-h', 'Show help message') do
        @options[:help] = true
      end
    end

    begin
      parser.parse!
    rescue OptionParser::ParseError => e
      STDERR.puts e
      STDERR.puts
      STDERR.puts "Please see './compile-passenger.rb --help' for valid options."
      exit 1
    end

    if !@options[:passenger_dir]
      abort '--passenger-dir must be specified'
    end
    if !@options[:output_dir]
      abort '--output-dir must be specified'
    end

    if @options[:help]
      puts parser
      exit 0
    end
  end

  def set_environment
    STDOUT.sync = true
    STDERR.sync = true
    if !cc_uses_ccache?
     set_env('USE_CCACHE', 1)
    end
    if @options[:timeout]
      spawn_timeout_killer(@options[:timeout])
    end
  end

  def spawn_timeout_killer(timeout)
    Process.setpgrp
    Thread.new do
      Thread.current.abort_on_exception = true
      sleep(timeout)
      STDERR.puts "*** TIMEOUT #{timeout} SECONDS ***"
      Process.kill('-TERM', Process.pid)
    end
  end

  def cc_uses_ccache?
    (cc = ENV['CC']) && (cc =~ /^ccache /)
  end

  def set_env(key, value)
    log "Setting environment variable: #{key}=#{value}"
    ENV[key] = value.to_s
  end

  def initialize_logger
    @logger = Logger.new(STDOUT)
  end

  def copy_codebase
    sh(sprintf("%s/copy-passenger-source-dir.sh %s /tmp/passenger",
      shesc(SELFDIR),
      shesc(@options[:passenger_dir])))
    Dir.chdir('/tmp/passenger')
  end

  def compile
    RUBY_VERSIONS.each do |ruby_version|
      sh "#{activate_library_compilation_environment}" \
        " rvm-exec ruby-#{ruby_version} env NOEXEC_DISABLE=1" \
        " drake native_support".strip

      output_file = Dir["buildout/ruby/ruby-#{ruby_version}-*/*.so"].first
      sh "#{strip_debug} #{output_file}"
      if @options[:holy_build_box]
        # We don't run hardening-check here because the Passenger
        # build system does not yet modify the mkmf Makefile
        # to properly pass environment variables like CFLAGS.
        sh "env LIBCHECK_ALLOW=libruby libcheck #{output_file}"
      end
    end

    sh "#{activate_exe_compilation_environment}" \
      " rvm-exec #{DEFAULT_RUBY_VERSION} drake nginx" \
      " -j #{@options[:concurrency]} OPTIMIZE=true".strip
    sh "#{strip_all} buildout/support-binaries/PassengerAgent"
    if @options[:holy_build_box]
      sh 'hardening-check -b buildout/support-binaries/PassengerAgent'
      sh 'libcheck buildout/support-binaries/PassengerAgent'
    end
  end

  def activate_library_compilation_environment
    if @options[:holy_build_box]
      "#{ROOT}/linux/support/activate-library-compilation-environment.sh"
    else
      nil
    end
  end

  def activate_exe_compilation_environment
    if @options[:holy_build_box]
      "#{ROOT}/linux/support/activate-exe-compilation-environment.sh"
    else
      nil
    end
  end

  def commit_output
    output_dir = @options[:output_dir]
    mkdir_p "#{output_dir}/support-binaries", verbose: true
    mkdir_p "#{output_dir}/ruby-extensions", verbose: true

    Dir['buildout/ruby/*'].each do |path|
      arch = File.basename(path)
      mkdir_p "#{output_dir}/ruby-extensions/#{arch}", verbose: true
      cp Dir["#{path}/*.so"], "#{output_dir}/ruby-extensions/#{arch}/",
        verbose: true
    end

    cp 'buildout/support-binaries/PassengerAgent',
      "#{@options[:output_dir]}/support-binaries/",
      verbose: true
  end
end

CompilePassenger.new.start
