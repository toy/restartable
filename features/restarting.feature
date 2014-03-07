Feature: Restarting

  Scenario Outline: Restarting and terminating
    Given I have invoked restartable with `<code>`

    When I have waited for 1 second
    Then I should see "^C to restart, double ^C to stop" in stderr
    And I should see "Hello world!" in stdout
    And there should be an inner process
    When I interrupt restartable
    Then I should see "Killing children…" and "Waiting ^C 0.5 second than restart…" in stderr
    And inner process should terminate

    When I have waited for 1 second
    Then I should see "^C to restart, double ^C to stop" in stderr
    And I should see "Hello world!" in stdout
    And there should be an inner process
    When I interrupt restartable twice
    Then I should see "Killing children…" and "Don't restart!" in stderr
    And inner process should terminate
    And restartable should finish

    Examples:
      | code                        |
      | $stdout.puts "Hello world!" |
      | $stdout.puts "Hello world!"; 100.times{ sleep 1 } |
      | exec 'echo "Hello world!"; 100.times{ sleep 1 }' |
      | system 'echo "Hello world!"; 100.times{ sleep 1 }' |
      | fork{ $stdout.puts "Hello world!"; 100.times{ sleep 1 } } |
      | fork{ fork{ fork{ $stdout.puts "Hello world!"; 100.times{ sleep 1 } } } } |
      | Signal.trap("INT"){}; Signal.trap("TERM"){}; $stdout.puts "Hello world!"; 100.times{ sleep 1 } |
