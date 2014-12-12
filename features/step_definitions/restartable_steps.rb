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
  Timeout.timeout(5) do
    expect(@stdout[0].gets).to include(string)
  end
end

Then(/^
  I\ should\ see\ "(.*?)"
  \ in\ stderr
  (?:\ within\ (\d+)\ seconds)?
$/x) do |arg, timeout|
  Timeout.timeout(timeout ? timeout.to_i : 5) do
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
  Timeout.timeout(5) do
    sleep 1 until Sys::ProcTable.ps.any?{ |pe| pe.ppid == @pid }
  end
end

Then(/^inner process should terminate$/) do
  Timeout.timeout(100) do
    sleep 1 until Sys::ProcTable.ps.none?{ |pe| pe.ppid == @pid }
  end
end

Then(/^restartable should finish$/) do
  Timeout.timeout(5) do
    Process.wait(@pid)
  end
end
