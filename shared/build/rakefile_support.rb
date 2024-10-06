require 'shellwords'
require 'fileutils'
require 'tmpdir'
require 'thread'
require 'paint'

ROOT = File.absolute_path(File.dirname(__FILE__) + '/../..')
RUBY_VERSIONS = File.read("#{ROOT}/shared/definitions/ruby_versions").split
DEFAULT_RUBY_VERSION = RUBY_VERSIONS.last

COMMAND_COLORS = [
  "CadetBlue1",
  "yellow1",
  "burlywood1",
  "DarkOliveGreen1",
  "gold",
  "LightSalmon",
  "DarkTurquoise",
  "chocolate1",
  "SpringGreen1",
  "HotPink1",
  "GreenYellow",
  "MediumOrchid1",
  "DeepSkyBlue",
  "chartreuse1",
  "aquamarine"
].freeze

$NEXT_COMMAND_ID = 1
$NEXT_COMMAND_ID_MUTEX = Mutex.new

class CommandError < SystemExit
  def initialize(status = 1)
    super(status)
  end
end


def initialize_rakefile!
  STDOUT.sync = true
  STDERR.sync = true
  ENV.delete('BUNDLER_ORIG_PATH')
  if path = ENV['FORCE_GEM_HOME_AND_PATH']
    ENV['GEM_HOME'] = ENV['GEM_PATH'] = path
  end
  set_constants_and_envvars
  load_passenger
  clear_work_dir if !SHOW_TASKS
end

def set_constants_and_envvars
  set_constant_and_envvar :SHOW_TASKS, getenv('SHOW_TASKS', 'false') == 'true'

  if !SHOW_TASKS
    set_constant_and_envvar :PASSENGER_DIR, getenv('PASSENGER_DIR')
    set_constant_and_envvar :OUTPUT_DIR, getenv('OUTPUT_DIR')
    set_constant_and_envvar :CACHE_DIR, getenv('CACHE_DIR')
    set_constant_and_envvar :WORK_DIR, getenv('WORK_DIR', lambda { create_temp_work_dir })
    set_constant_and_envvar :CONCURRENCY, getenv('CONCURRENCY', '2').to_i
    set_constant_and_envvar :IN_HOLY_BUILD_BOX, getenv('IN_HOLY_BUILD_BOX', 'false') == 'true'
    set_constant_and_envvar :NGINX_DIR, getenv('NGINX_DIR', nil)
    set_constant_and_envvar :RVM_EXEC, getenv('RVM_EXEC', nil)
  end
end

def load_passenger
  if !SHOW_TASKS
    require("#{PASSENGER_DIR}/src/ruby_supportlib/phusion_passenger")
    PhusionPassenger.locate_directories
    PhusionPassenger.require_passenger_lib('constants')
    set_constant_and_envvar :NGINX_VERSION, getenv('NGINX_VERSION',
      PhusionPassenger::PREFERRED_NGINX_VERSION)
  end
end

def getenv(name, *default)
  if default.size == 0
    ENV[name] || abort("Environment variable required: #{name}")
  else
    default = default[0]
    result = ENV.fetch(name, default)
    result = result.call if result.respond_to?(:call)
    result
  end
end

def set_constant_and_envvar(name, value)
  Kernel.const_set(name.to_sym, value)
  ENV[name.to_s] = value.to_s
end

def shesc(path)
  Shellwords.escape(path)
end

def log(message)
  STDOUT.write("#{message}\n")
end

def logf(*args)
  log(sprintf(*args))
end

def activate_library_compilation_environment
  if IN_HOLY_BUILD_BOX
    "#{shesc ROOT}/linux/support/activate-library-compilation-environment.sh"
  else
    nil
  end
end

def activate_passenger_agent_compilation_environment
  if IN_HOLY_BUILD_BOX
    "#{shesc ROOT}/linux/support/activate-passenger-agent-compilation-environment.sh"
  else
    "#{shesc ROOT}/macos/support/activate-passenger-agent-compilation-environment.sh"
  end
end

def activate_nginx_compilation_environment
  if IN_HOLY_BUILD_BOX
    "#{shesc ROOT}/linux/support/activate-nginx-compilation-environment.sh"
  else
    nil
  end
end

def agent_command_builder
  "#{activate_passenger_agent_compilation_environment}" \
    " #{RVM_EXEC} ruby-#{DEFAULT_RUBY_VERSION}" \
    " env NOEXEC_DISABLE=1 CCACHE_BASEDIR=#{shesc $PASSENGER_SOURCE_DIR_COPY}" \
    " #{forced_gem_home_and_path_envs}" \
    " rake nginx_without_native_support" \
    " -j #{CONCURRENCY} OPTIMIZE=true OUTPUT_DIR=".strip
end

def library_command_builder(ruby_version)
  "#{activate_library_compilation_environment}" \
    " #{RVM_EXEC} ruby-#{ruby_version}" \
    " env NOEXEC_DISABLE=1 CCACHE_BASEDIR=#{shesc $PASSENGER_SOURCE_DIR_COPY}" \
    " #{forced_gem_home_and_path_envs}" \
    " rake native_support OUTPUT_DIR=".strip
end

def forced_gem_home_and_path_envs
  if path = ENV['FORCE_GEM_HOME_AND_PATH']
    "GEM_HOME=#{shesc path} GEM_PATH=#{shesc path}"
  end
end

def nginx_tarball_basename
  "nginx-#{NGINX_VERSION}.tar.gz"
end

def nginx_tarball_url
  "https://nginx.org/download/#{nginx_tarball_basename}"
end

def download(url, dir)
  basename = url.sub(/.*\//, '')
  run("curl --fail -L -o #{shesc dir}/#{basename} #{shesc url}")
  "#{dir}/#{basename}"
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

def get_next_command_id
  $NEXT_COMMAND_ID_MUTEX.synchronize do
    result = $NEXT_COMMAND_ID
    $NEXT_COMMAND_ID += 1
    result
  end
end

def run(command, options = {})
  command_id = get_next_command_id
  command_color = COMMAND_COLORS[command_id % COMMAND_COLORS.size]
  command_prefix = Paint[sprintf("%02d", command_id), command_color]

  logf(" %s %s",
    command_prefix,
    Paint[sprintf('### Running: %s', command), :bold])

  real_command = "/bin/bash -c #{shesc(command)} 2>&1"
  if options[:chdir]
    real_command = "cd #{shesc options[:chdir]} && #{real_command}"
    logf(' %s (in %s)', command_prefix, options[:chdir])
  end
  IO.popen(real_command, 'rb') do |io|
    while !io.eof?
      line = io.readline.chomp
      logf(" %s %s", command_prefix, line)
    end
  end

  if $?.nil? || $?.exitstatus != 0
    logf(" %s %s", command_prefix, Paint['*** Command failed', :red])
    raise CommandError
  end
end

def manipulate_file(path)
  content = File.open(path, 'rb') do |f|
    f.read
  end
  content = yield(content.dup)
  File.open(path, 'wb') do |f|
    f.write(content)
  end
end

def libext
  if RUBY_PLATFORM =~ /darwin/
    'bundle'
  else
    'so'
  end
end

def create_temp_work_dir
  path = Dir.mktmpdir
  at_exit do
    log("Removing #{path}")
    FileUtils.remove_entry_secure(path)
  end
  path
end

def clear_work_dir
  Dir.glob("*", flags: File::FNM_DOTMATCH, base: WORK_DIR).each do |basename|
    FileUtils.remove_entry_secure(File.join(WORK_DIR, basename)) unless basename == "."
  end
end
