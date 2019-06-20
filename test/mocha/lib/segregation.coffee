ENV_VAR = 'IMJS_TESTS'

TRIGGER_UNIT = 'UNIT'
TRIGGER_INTEGRATION = 'INTEGRATION'


# Developer needs to explicitly mention if he wants to run unit tests
unitTests = ->
    process.env[ENV_VAR] is TRIGGER_UNIT

# As integration tests should be the default behaviour,
# if the user doesn't want to run unit tests explicitly,
# run the integration tests (current case)
# (Change this behaviour in case the build changes)
integrationTests = ->
    not unitTests()

# Defined just to keep consistency, both tests implies those which
# can be used as both unit and integration tests
# WARNING: The nature of the test run would still depend upon
# which type of tests the developer wants to run.
# In case he wants unit tests, the responses will be mocked, else not
# This will be handled in the mocking function only
bothTests = ->
    true

module.exports = 
    unitTests: unitTests
    integrationTests: integrationTests
    bothTests: bothTests