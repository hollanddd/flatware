require 'pathname'

dir = Pathname.new(__FILE__).dirname
$:.unshift dir.join('../../lib').to_s

ENV['PATH'] = [Pathname.new('.').expand_path.join('bin').to_s, ENV['PATH']].join(':')
require 'aruba/cucumber'
require 'rspec/expectations'
Dir[dir.join('../../spec/support/**/*.rb')].each {|f| require f }

After do
  flatware_pids = `ps -o command,pid | awk '/^flatware/{ print $NF }'`
  `echo "#{flatware_pids}" | xargs kill -6`
  flatware_pids.should be_empty, "flatware left orphans! (don't worry, I killed them.)"
end
