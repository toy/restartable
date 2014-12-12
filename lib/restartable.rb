# encoding: UTF-8

require 'sys/proctable'
require 'colored'
require 'thread'

class Restartable
  def self.version
    Gem.loaded_specs['restartable'].version.to_s rescue 'DEV'
  end

  def initialize(options = {}, &block)
    @options, @block = options, block
    run!
  end

private

  def run!
    Signal.trap('INT') do
      interrupt!
    end
    Signal.trap('TERM') do
      terminate!
    end

    until @stop
      @interrupted = nil
      $stderr << "^C to restart, double ^C to stop\n".green
      @cpid = fork do
        Signal.trap('INT', 'DEFAULT')
        Signal.trap('TERM', 'DEFAULT')
        @block.call
      end
      sleep 0.1 until @interrupted
      kill_children!
      unless @stop
        $stderr << "Waiting ^C 0.5 second than restart…\n".yellow.bold
        sleep 0.5
      end
    end
  end

  def interrupt!
    if @interrupted
      @stop = true
      $stderr << "Don't restart!\n".red.bold
    else
      @interrupted = true
    end
  end

  def terminate!
    interrupt!
    interrupt!
  end

  WAIT_SIGNALS = [[5, 'INT'], [3, 'INT'], [1, 'INT'], [3, 'TERM'], [5, 'KILL']]

  def kill_children!
    until (pids = children_pids).empty?
      $stderr << "Killing children…\n".yellow.bold

      signal_pair = 0

      begin
        time, signal = WAIT_SIGNALS[signal_pair]
        Timeout.timeout(time) do
          Process.waitall
          wait_children
        end
      rescue Timeout::Error
        $stderr << "…SIG#{signal}…\n".yellow
        signal_children!(signal)
        retry if WAIT_SIGNALS[signal_pair += 1]
      end
    end
  end

  def wait_children
    children_pids.each do |pid|
      begin
        loop do
          Process.kill(0, pid)
          sleep 1
        end
      rescue Errno::ESRCH
      end
    end
  end

  def signal_children!(signal)
    children_pids.each do |pid|
      begin
        Process.kill(signal, pid)
      rescue Errno::ESRCH
      end
    end
  end

  def children_pids
    pgrp = Process.getpgrp
    Sys::ProcTable.ps.select do |pe|
      pgrp == case
      when pe.respond_to?(:pgid)
        pe.pgid
      when pe.respond_to?(:pgrp)
        pe.pgrp
      when pe.respond_to?(:ppid)
        pe.ppid
      else
        raise 'Can\'t find process group id'
      end
    end.map(&:pid) - [$$]
  end
end
