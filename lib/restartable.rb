# encoding: UTF-8

require 'sys/proctable'
require 'colored'
require 'thread'

class Restartable
  def self.version
    Gem.loaded_specs['restartable'].version.to_s rescue 'DEV'
  end

  def initialize(options, &block)
    @options, @block = options, block
    run!
  end

private

  def run!
    @mutex = Mutex.new

    receiver, sender = IO.pipe
    @trap_sender = Process.fork do
      receiver.close
      Signal.trap('PIPE', 'EXIT')
      synced_trap('INT'){ Marshal.dump(:int, sender) }
      loop{ sleep }
    end
    sender.close

    Signal.trap('INT', 'IGNORE')
    synced_trap('TERM'){ terminate! }

    int_receiver = Thread.new do
      until receiver.eof?
        Marshal.load(receiver) && interrupt!
      end
    end
    cycle
  end

  def interrupt!
    unless @interrupted
      @interrupted = true
      Thread.list.each do |thread|
        unless Thread.current == thread
          thread.raise SignalException.new('INT')
        end
      end
    else
      no_restart!
    end
  end

  def terminate!
    no_restart!
    interrupt!
  end

  def no_restart!
    @stop = true
    puts 'Don\'t restart!'.red.bold
  end

  def synced_trap(signal, &block)
    Signal.trap(signal) do
      Thread.new do
        @mutex.synchronize(&block)
      end
    end
  end

  WAIT_SIGNALS = [[1, 'INT'], [1, 'INT'], [1, 'INT'], [1, 'TERM'], [5, 'KILL']]

  def cycle
    until @stop
      @interrupted = false
      puts '^C to restart, double ^C to stop'.green
      begin
        @block.call
        loop{ sleep } # wait ^C even if block finishes
      rescue SignalException
        unless children_pids.empty?
          puts 'Killing children…'.yellow.bold
          ripper = Thread.new do
            WAIT_SIGNALS.each do |time, signal|
              sleep time
              puts "…SIG#{signal}…".yellow
              children_pids.each do |child_pid|
                Process.kill(signal, child_pid)
              end
            end
          end
          children_pids.each do |child_pid|
            Process.wait child_pid
          end
          ripper.terminate
        end
        unless @stop
          puts 'Waiting ^C 0.5 second than restart…'.yellow.bold
          sleep 0.5
        end
      end
    end
  end

  def children_pids
    Sys::ProcTable.ps.select{ |pe| $$ == pe.ppid }.map(&:pid) - [@trap_sender]
  end
end
