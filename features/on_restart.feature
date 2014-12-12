Feature: Run action on restart

  Scenario: Invoking with on restart action
    Given I have set on restart to `$stdout.puts 'Restart!'`
    And I have invoked restartable with `$stdout.puts 'Running!'`

    When I have waited for 1 second
    Then I should see "^C to restart, double ^C to stop" in stderr
    And I should see "Running!" in stdout
    And there should be a child process
    When I interrupt restartable
    Then I should see "Killing children…" and "Waiting ^C 0.5 second than restart…" in stderr
    And child process should terminate

    When I have waited for 1 second
    Then I should see "Restart!" in stdout
    And I should see "^C to restart, double ^C to stop" in stderr
    And I should see "Running!" in stdout
    And there should be a child process
    When I interrupt restartable twice
    Then I should see "Killing children…" and "Don't restart!" in stderr
    And child process should terminate
    And restartable should finish
    And I should not see "Restart!" in stdout
