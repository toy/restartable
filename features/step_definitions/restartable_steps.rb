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

Then(/^I should see "(.*?)" in stderr$/) do |arg|
  Timeout::timeout(60) do
    strings = arg.split(/".*?"/)
    until strings.empty?
      line = @stderr[0].gets
      strings.reject! do |string|
        line.include?(string)
      end
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

Then(/^there should be an inner process$/) do
  Sys::ProcTable.ps.any?{ |pe| pe.ppid == @cpid }
end

Then(/^inner process should terminate$/) do
  Sys::ProcTable.ps.none?{ |pe| pe.ppid == @cpid }
end

Then(/^restartable should finish$/) do
  Timeout::timeout(5) do
    Process.wait(@pid)
  end
end
