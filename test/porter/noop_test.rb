require 'test_helper'
require 'json'

client = Aws::States::Client.new(
  region: region_name,
  credentials: credentials,
  # ...
)

describe :porter, :execution do
  describe :noop do
    req = client.start_execution({
      state_machine_arn: CONFIG.PORTER_STATE_MACHINE_ARN,
      input: {
        Job: {
          Id: 'porter-test-no-op',
          Source: {
            Mode: 'HTTP',
            URL: 'some-url'
          }
        }
      }.to_json
    })

    max_retries = 5

    begin
      desc = client.describe_execution({
        execution_arn: req.execution_arn,
      })

      raise RequestError if desc.status == 'RUNNING'
    rescue RequestError => e
      if retries <= max_retries
        retries += 1
        sleep 2 ** retries
        retry
      else
        raise "Timeout: #{e.message}"
      end
    end

    desc['JobResult']['Job']['Id'].must_equal 'porter-test-no-op'
    desc['JobResult']['State'].must_equal 'DONE'
    desc['JobResult']['FailedTasks'].must_equal []
    desc['JobResult']['TaskResults'].must_equal []
  end
end
