# frozen_string_literal: true

require 'restartable'

def children
  Sys::ProcTable.ps.select do |pe|
    next if pe.pid == @pid

    @pid == case
    when pe.respond_to?(:pgid) then pe.pgid
    when pe.respond_to?(:pgrp) then pe.pgrp
    when pe.respond_to?(:ppid) then pe.ppid
    else fail 'Can\'t find process group id'
    end
  end
end

Given(/^I have set on restart to `(.+)`$/) do |command|
  (@on_restart ||= []) << proc{ eval(command) }
end

Given(/^I have invoked restartable with `(.+)`$/) do |command|
  @stdout = IO.pipe
  @stderr = IO.pipe

  @pid = fork do
    Process.setpgrp

    @stdout[0].close
    $stdout.reopen(@stdout[1])

    @stderr[0].close
    $stderr.reopen(@stderr[1])

    Restartable.new(on_restart: @on_restart) do
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

Then(/^I should see "(.+)" in std(out|err)$/) do |arg, io_name|
  step %(I should see "#{arg}" in std#{io_name} within 5 seconds)
end
Then(/^I should see "(.+)" in std(out|err) within (\d+) seconds$/) do |arg, io_name, timeout|
  io = (io_name == 'out' ? @stdout : @stderr)[0]
  Timeout.timeout(timeout.to_i) do
    strings = arg.split(/".+?"/)
    until strings.empty?
      line = io.gets
      strings.reject! do |string|
        line.include?(string)
      end
    end
  end
end

Then(/^I should not see "(.+)" in std(out|err)$/) do |arg, io_name|
  io = (io_name == 'out' ? @stdout : @stderr)[0]
  strings = arg.split(/".+?"/)
  while (line = io.gets)
    if strings.any?{ |string| line.include?(string) }
      fail "Got #{line}"
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
    sleep 0.3 while children.empty?
  end
end

Then(/^child process should terminate$/) do
  step %(child process should terminate within 5 seconds)
end
Then(/^child process should terminate within (\d+) seconds$/) do |timeout|
  Timeout.timeout(timeout.to_i) do
    sleep 0.3 until children.empty?
  end
end

Then(/^restartable should finish$/) do
  Timeout.timeout(5) do
    Process.wait(@pid)
  end
end
