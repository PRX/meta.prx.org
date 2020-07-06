require 'test_helper'
require 'aws-sdk-states'
require 'json'

step_functions = Aws::States::Client.new(
  region: 'us-east-1'
)

describe :porter do
  describe :inspect do
    it 'returns the basic execution output' do
      req = step_functions.start_execution({
        state_machine_arn: CONFIG.PORTER_STATE_MACHINE_ARN,
        input: {
          Job: {
            Id: 'porter-test-inspect',
            Source: {
              Mode: 'HTTP',
              URL: 'https://media.prx.org/emailimages/ieeespectrum.png'
            },
            Tasks: [
              {
                Type: "Inspect"
              }
            ]
          }
        }.to_json
      })

      max_retries = 60
      retries = 0

      begin
        desc = step_functions.describe_execution({
          execution_arn: req.execution_arn,
        })

        raise RuntimeError if desc.status == 'RUNNING'
      rescue RuntimeError => e
        if retries <= max_retries
          retries += 1
          sleep 2
          retry
        else
          raise "Timeout: #{e.message}"
        end
      end

      output = JSON.parse(desc.output)

      output['JobResult']['Job']['Id'].must_equal 'porter-test-inspect'
      output['JobResult']['State'].must_equal 'DONE'
      output['JobResult']['FailedTasks'].must_equal []
      output['JobResult']['TaskResults'].length.must_equal 1
      output['JobResult']['TaskResults'][0]['Inspection']['Image']['Format'].must_equal 'png'
    end
  end
end
