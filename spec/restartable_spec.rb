$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rspec'
require 'restartable'

describe Restartable do
  def check_for(&block)
    receiver, sender = IO.pipe

    pid = fork do
      receiver.close
      Process.setpgrp
      STDOUT.reopen('/dev/null', 'w')
      STDERR.reopen('/dev/null', 'w')
      Restartable.new do
        Marshal.dump(:started, sender)
        block.call
      end
    end
    sender.close

    2.times do
      sleep 1
      Marshal.load(receiver).should == :started
      Process.kill('INT', -pid)
    end

    sleep 1
    Marshal.load(receiver).should == :started
    Process.kill('INT', -pid)
    sleep 0.1
    Process.kill('INT', -pid)

    Process.wait(pid)

    receiver.should be_eof
  end

  it "should work for sleep" do
    check_for do
      sleep 30
    end
  end

  it "should work for exec" do
    check_for do
      exec 'sleep 30'
    end
  end

  it "should work for system" do
    check_for do
      system 'sleep 30'
    end
  end
end
