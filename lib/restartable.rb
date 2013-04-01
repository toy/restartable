# encoding: UTF-8

require 'sys/proctable'
require 'colored'

class Restartable
  def self.version
    Gem.loaded_specs['restartable'].version.to_s rescue 'DEV'
  end

  WAIT_SIGNALS = [[1, 'INT'], [1, 'INT'], [1, 'INT'], [1, 'TERM'], [5, 'KILL']]

  def initialize(options, &block)
    @options, @block = options, block
    @mutex = Mutex.new
    synced_trap('INT'){ interrupt! }
    synced_trap('TERM'){ no_restart!; interrupt! }
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

  def no_restart!
    @stop = true
    puts 'Don\'t restart!'.red.bold
  end

  def cycle
    until @stop
      @interrupted = false
      puts '^C to restart, double ^C to stop'.green
      begin
        @block.call
        sleep # wait ^C even if block finishes
      rescue SignalException
        unless children.empty?
          puts 'Killing children…'.yellow.bold
          ripper = Thread.new do
            WAIT_SIGNALS.each do |time, signal|
              sleep time
              puts "…SIG#{signal}…".yellow
              children.each do |child|
                Process.kill(signal, child.pid)
              end
            end
          end
          Process.waitall
          ripper.terminate
        end
        unless @stop
          puts 'Waiting ^C 0.5 second than restart…'.yellow.bold
          sleep 0.5
        end
      end
    end
  end

private

  def synced_trap(signal, &block)
    Signal.trap(signal) do
      Thread.new do
        @mutex.synchronize(&block)
      end
    end
  end

  def children
    pid = Process.pid
    Sys::ProcTable.ps.select{ |pe| pid == pe.ppid }
  end
end
