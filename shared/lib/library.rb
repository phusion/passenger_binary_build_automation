require 'shellwords'
require 'paint'

module Library
private
  class CommandError < SystemExit
    def initialize(status = 1)
      super(status)
    end
  end

  def log(message)
    if STDOUT.tty?
      puts "\e[1m# #{message}\e[0m"
    else
      puts "# #{message}"
    end
  end

  def sh(command, env = {})
    real_command = build_real_command(command, env)
    log("Running: #{real_command}")

    IO.popen("/bin/bash -c #{Shellwords.escape(real_command)} 2>&1", 'rb') do |io|
      while !io.eof?
        line = io.readline.chomp
        if line =~ /^\e\[44m\e\[33m\e\[1m/
          # Looks like a header. Replace color codes with an ASCII
          # indicator.
          line.sub!(/^\e\[44m\e\[33m\e\[1m/, "--> ")
          line.sub!("\e[0m", '')
        elsif line !~ /^--> /
          line = "    #{line}"
        end
        log(line)
      end
    end

    if $?.nil? || $?.exitstatus != 0
      log(Paint["*** Command failed: ", :red] + command)
      raise CommandError
    end
  end

  def build_real_command(command, env)
    if env.empty?
      command
    else
      result = "env "
      env.each_pair do |key, val|
        result << "#{Shellwords.escape key.to_s}=#{Shellwords.escape val.to_s} "
      end
      result << command
      result
    end
  end

  def shesc(path)
    Shellwords.escape(path)
  end

  def strip_debug
    if RUBY_PLATFORM =~ /darwin/
      'strip -S'
    else
      'strip --strip-debug'
    end
  end

  def strip_all
    if RUBY_PLATFORM =~ /darwin/
      'strip'
    else
      'strip --strip-all'
    end
  end
end
