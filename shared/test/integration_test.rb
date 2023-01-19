# encoding: utf-8
#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2013-2016 Phusion Holding B.V.
#
#  "Passenger", "Phusion Passenger" and "Union Station" are registered
#  trademarks of Phusion Holding B.V.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

passenger_root = ENV['PASSENGER_ROOT'] || abort('Please specify PASSENGER_ROOT')
PACKAGED_ARTEFACTS_DIR = ENV['PACKAGED_ARTEFACTS_DIR'] || abort('Please specify UNPACKAGED_ARTEFACTS_DIR')
UNPACKAGED_ARTEFACTS_DIR = ENV['UNPACKAGED_ARTEFACTS_DIR'] || abort('Please specify PACKAGED_ARTEFACTS_DIR')

require("#{passenger_root}/src/ruby_supportlib/phusion_passenger")
PhusionPassenger.locate_directories
PhusionPassenger.require_passenger_lib 'constants'
PhusionPassenger.require_passenger_lib 'platform_info/operating_system'
PhusionPassenger.require_passenger_lib 'platform_info/binary_compatibility'

require 'tmpdir'
require 'fileutils'
require 'webrick'
require 'open-uri'
require 'shellwords'

Dir.chdir(PhusionPassenger.build_system_dir)
ENV['PATH'] = "#{PhusionPassenger.bin_dir}:#{ENV['PATH']}"
# This environment variable changes Passenger Standalone's behavior,
# so ensure that it's not set.
ENV.delete('PASSENGER_DEBUG')


module TestHelper
  def sh(*command)
    if !system(*command)
      abort "Command failed: #{command.join(' ')}"
    end
  end

  def shesc(path)
    Shellwords.escape(path)
  end
end


describe 'Passenger binaries' do
  include TestHelper

  specify 'PassengerAgent is runnable' do
    sh("env LD_BIND_NOW=1 #{shesc UNPACKAGED_ARTEFACTS_DIR}/support-binaries/PassengerAgent --help >/dev/null")
  end

  specify 'nginx is runnable' do
    nginx_paths = Dir["#{UNPACKAGED_ARTEFACTS_DIR}/support-binaries/nginx-*"]
    expect(nginx_paths).not_to be_empty

    nginx_paths.each do |nginx_path|
      sh("env LD_BIND_NOW=1 #{shesc nginx_path} -V &>/dev/null")
    end
  end
end

describe 'Downloaded Passenger binaries' do
  include TestHelper

  before :each do
    @temp_dir = Dir.mktmpdir
    File.open("#{PhusionPassenger.resources_dir}/release.txt", 'w').close

    # Prevent concurrent usage of ~/.passenger
    lock_path = File.expand_path("~/#{PhusionPassenger::USER_NAMESPACE_DIRNAME}.lock")
    @lock = File.open(lock_path, 'w')
    @lock.flock(File::LOCK_EX)

    @user_dir = File.expand_path("~/#{PhusionPassenger::USER_NAMESPACE_DIRNAME}")
    if File.exist?("#{@user_dir}.old")
      raise "#{@user_dir} exists. Please fix this first."
    end
    if File.exist?(@user_dir)
      FileUtils.mv(@user_dir, "#{@user_dir}.old")
    end

    Dir.mkdir('download_cache')
  end

  after :each do
    FileUtils.rm_rf(@user_dir)
    if File.exist?("#{@user_dir}.old")
      FileUtils.mv("#{@user_dir}.old", @user_dir)
    end

    FileUtils.rm_rf('download_cache')

    FileUtils.remove_entry_secure(@temp_dir)

    @lock.close if @lock

    File.unlink("#{PhusionPassenger.resources_dir}/release.txt")
  end

  let(:nginx_version) { PhusionPassenger::PREFERRED_NGINX_VERSION }
  let(:compat_id) { PhusionPassenger::PlatformInfo.cxx_binary_compatibility_id }
  let(:passenger_port) { 4204 }
  let(:unused_port) { 4205 }

  def start_server(document_root)
    server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1',
      Port: 0,
      DocumentRoot: document_root,
      Logger: WEBrick::Log.new('/dev/null'),
      AccessLog: [])
    Thread.new do
      Thread.current.abort_on_exception = true
      server.start
    end
    [server, "http://127.0.0.1:#{server.config[:Port]}"]
  end


  specify 'Passenger Standalone is able to use the binaries' do
    FileUtils.cp_r(Dir["#{PACKAGED_ARTEFACTS_DIR}/*"], 'download_cache/')

    Dir.chdir(@temp_dir) do
      File.open('config.ru', 'w') do |f|
        f.write(%Q{
          app = lambda do |env|
            [200, { 'Content-Type' => 'text/plain' }, ['ok']]
          end
          run app
        })
      end
      Dir.mkdir('public')
      Dir.mkdir('tmp')
      Dir.mkdir('log')

      begin
        sh('passenger start ' \
          "-p #{passenger_port} " \
          '-d ' \
          '--no-compile-runtime ' \
          "--binaries-url-root http://127.0.0.1:#{unused_port} " \
          '>log/start.log 2>&1')
      rescue Exception
        puts ' --> Log file contents:'
        system('cat log/start.log')
        raise
      end

      begin
        URI.open("http://127.0.0.1:#{passenger_port}/") do |f|
          expect(f.read).to eq('ok')
        end
      rescue
        puts ' --> Log file contents:'
        system("cat log/passenger.#{passenger_port}.log")
        raise
      ensure
        sh "passenger stop -p #{passenger_port}"
      end
    end
  end

  describe 'helper-scripts/download_binaries/extconf.rb' do
    if PhusionPassenger::PlatformInfo.os_name_simple == 'linux'
      it 'succeeds in downloading all necessary binaries' do
        Dir.mkdir("#{@temp_dir}/server_root")
        Dir.mkdir("#{@temp_dir}/server_root/#{PhusionPassenger::VERSION_STRING}")

        server, url_root = start_server("#{@temp_dir}/server_root")
        begin
          FileUtils.cp_r(Dir["#{PACKAGED_ARTEFACTS_DIR}/*"],
            "#{@temp_dir}/server_root/#{PhusionPassenger::VERSION_STRING}/")
          sh("env BINARIES_URL_ROOT=#{url_root}" \
            ' ruby src/helper-scripts/download_binaries/extconf.rb' \
            ' --abort-on-error')
          expect(Dir['download_cache/*']).not_to be_empty
        rescue
          p Dir["#{PACKAGED_ARTEFACTS_DIR}/*"]
          p Dir["#{@temp_dir}/server_root/#{PhusionPassenger::VERSION_STRING}/*"]
          raise
        ensure
          File.unlink('Makefile') rescue nil
          server.stop
        end
      end
    end

    it 'fails at downloading all necessary binaries if one of them does not exist' do
      Dir.mkdir("#{@temp_dir}/server_root")

      server, url_root = start_server("#{@temp_dir}/server_root")
      begin
        result = system("env BINARIES_URL_ROOT=#{url_root}" \
          ' ruby src/helper-scripts/download_binaries/extconf.rb' \
          ' --abort-on-error')
        expect(result).to be_falsey
      ensure
        File.unlink('Makefile') rescue nil
        server.stop
      end
    end
  end
end
