World ProcessSupport, WaitingSupport

When 'I start flatware' do
  @process = run('flatware').instance_variable_get(:@process)
  wait_until { child_pids(@process.pid).any? }
end

When 'I hit CTRL-C before it is done' do
  Process.kill 'INT', @process.pid
end

Then 'I am back at the prompt' do
  wait_until(3) { @process.exited? }
  @process.should be_exited
end

Then 'I see a summary of unfinished work' do
  assert_partial_output 'skipped', all_output
end
