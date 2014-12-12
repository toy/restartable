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

Then(/^
  I\ should\ see\ "(.*?)"
  \ in\ std(out|err)
  (?:\ within\ (\d+)\ seconds)?
$/x) do |arg, io_name, timeout|
  io = (io_name == 'out' ? @stdout : @stderr)[0]
  Timeout.timeout(timeout ? timeout.to_i : 5) do
    strings = arg.split(/".*?"/)
    until strings.empty?
      line = io.gets
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
  step 'I interrupt restartable'
  sleep 0.1
  step 'I interrupt restartable'
end

Then(/^there should be a child process$/) do
  Timeout.timeout(5) do
    sleep 1 until Sys::ProcTable.ps.any?{ |pe| pe.ppid == @pid }
  end
end

Then(/^child process should terminate$/) do
  Timeout.timeout(100) do
    sleep 1 until Sys::ProcTable.ps.none?{ |pe| pe.ppid == @pid }
  end
end

Then(/^restartable should finish$/) do
  Timeout.timeout(5) do
    Process.wait(@pid)
  end
end
