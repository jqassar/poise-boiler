#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rspec'
require 'rspec/its'
require 'mixlib/shellout'
require 'poise_boiler'

module PoiseBoilerHelper
  extend RSpec::SharedContext
  around do |example|
    Dir.mktmpdir('poise_boiler_test') do |path|
      example.metadata[:poise_boiler_temp_path] = path
      example.run
    end
  end
  let(:temp_path) do |example|
    example.metadata[:poise_boiler_temp_path]
  end

  module ClassMethods
    def command(cmd=nil, options={}, &block)
      subject do
        cmd = block.call if block
        Mixlib::ShellOut.new(
          "bundle exec #{cmd}",
          {
            cwd: temp_path,
            environment: {
              'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __FILE__),
            },
          }.merge(options),
        ).tap do |cmd|
          cmd.run_command
          cmd.error!
        end
      end
    end

    def file(path, content=nil, &block)
      before do
        content = block.call if block
        full_path = File.join(temp_path, path)
        FileUtils.mkdir_p(File.dirname(full_path))
        IO.write(full_path, content)
      end
    end

    def included(klass)
      super
      klass.extend ClassMethods
    end
  end

  extend ClassMethods
end

RSpec.configure do |config|
  # Basic configuraiton
  config.run_all_when_everything_filtered = true
  config.filter_run(:focus)

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.include PoiseBoilerHelper
end
