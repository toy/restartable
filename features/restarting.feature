Feature: Restarting

  Scenario Outline: Restarting and terminating
    Given I have invoked restartable with `<code>`

    When I have waited for 1 second
    Then I should see "^C to restart, double ^C to stop" in stderr
    And I should see "Hello world!" in stdout
    And there should be an inner process
    When I interrupt restartable
    Then I should see "Killing children…" in stderr
    And I should see "Waiting ^C 0.5 second than restart…" in stderr within <timeout> seconds
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
      | code                                                                                           | timeout |
      | $stdout.puts "Hello world!"                                                                    | 5       |
      | $stdout.puts "Hello world!"; 100.times{ sleep 1 }                                              | 5       |
      | exec 'echo "Hello world!"; sleep 100'                                                          | 5       |
      | system 'echo "Hello world!"; sleep 100'                                                        | 5       |
      | fork{ $stdout.puts "Hello world!"; 100.times{ sleep 1 } }                                      | 5       |
      | fork{ fork{ fork{ $stdout.puts "Hello world!"; 100.times{ sleep 1 } } } }                      | 5       |
      | Signal.trap("INT"){}; $stdout.puts "Hello world!"; 100.times{ sleep 1 }                        | 15      |
      | Signal.trap("INT"){}; Signal.trap("TERM"){}; $stdout.puts "Hello world!"; 100.times{ sleep 1 } | 25      |
