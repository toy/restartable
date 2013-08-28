require 'restartable'

Given(/^I have invoked restartable with `(.*?)`$/) do |command|
  @stdout = IO.pipe
  @stderr = IO.pipe

  @pid = fork do
    Process.setpgrp

    @stdout[0].close
    STDOUT.reopen(@stdout[1])

    @stderr[0].close
    STDERR.reopen(@stderr[1])

    Restartable.new do
      Signal.trap('INT', 'EXIT')
      eval(command)
    end
  end

  @stdout[1].close
  @stderr[1].close
end

When(/^I have waited for (\d+) second$/) do |seconds|
  sleep seconds.to_i
end

Then(/^I should see "(.*?)" in stdout$/) do |string|
  Timeout::timeout(5) do
    @stdout[0].gets.should include(string)
  end
end

Then(/^I should see "(.*?)" in (?:last (\d+) lines of )?stderr$/) do |arg, line_count|
  Timeout::timeout(5) do
    strings = arg.split(/".*?"/)
    line_count = line_count ? line_count.to_i : strings.length
    got = line_count.times.map{ @stderr[0].gets }.join
    strings.each do |string|
      got.should include(string)
    end
  end
end

When(/^I interrupt restartable$/) do
  Process.kill('INT', -@pid)
end

When(/^I interrupt restartable twice$/) do
  Process.kill('INT', -@pid)
  sleep 0.1
  Process.kill('INT', -@pid)
end

Then(/^inner process should terminate$/) do
end

Then(/^restartable should finish$/) do
  Process.wait(@pid)
end
