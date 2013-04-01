require 'sys/proctable'
require 'colored'

class Restartable
  def self.version
    Gem.loaded_specs['restartable'].version.to_s rescue 'DEV'
  end

  def initialize(options, &block)
    @options, @block = options, block
    cycle
  end

  def cycle
    puts '^C to restart, double ^C to stop'.red
    loop do
      begin
        @block.call
        sleep
      rescue SignalException
        begin
          until children.empty?
            sleep 1
            children.each do |child|
              Process.detach(child.pid)
              Process.kill('TERM', child.pid)
            end
          end
          unless @stop
            puts 'Waiting ^C 0.5 second and block death than restart...'.yellow.bold
            sleep 0.5
          end
        rescue SignalException
          @stop = true
          puts 'Don\'t restart'.red
          retry
        end
      end
      break if @stop
      puts 'Restarting...'.green
    end
  end

private

  def children
    pid = Process.pid
    Sys::ProcTable.ps.select{ |pe| pid == pe.ppid }
  end
end
