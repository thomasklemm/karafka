# frozen_string_literal: true

# Karafka should recover from critical errors that happened in the workers while consuming
# jobs. It should notify on a proper channel and do other stuff
#
# @note This test is a bit special as due to how Karafka operates, when unexpected issue happens
#   in particular moments, it can bubble up and exit 2

setup_karafka(allow_errors: true) do |config|
  config.concurrency = 1
end

class Listener
  def on_error_occurred(event)
    DT[:errors] << event
  end
end

SuperException = Class.new(Exception)

Karafka.monitor.subscribe(Listener.new)

elements = Array.new(5) { SecureRandom.uuid }

class Consumer < Karafka::BaseConsumer
  def consume
    raise SuperException
  end
end

draw_routes(Consumer)

elements.each { |data| produce(DT.topic, data) }

raised = false

begin
  start_karafka_and_wait_until do
    # This means, that listener received critical error
    DT[:errors].size >= 1
  end
rescue SuperException
  raised = true
end

assert_equal false, raised
assert_equal 1, DT[:errors].size
assert_equal 'error.occurred', DT[:errors].first.id
assert_equal 'worker.process.error', DT[:errors].first.payload[:type]
