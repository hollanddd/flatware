require 'benchmark'
module Flatware
  class Worker

    def self.listen!
      new.listen
    end

    def self.spawn(worker_count)
      worker_count.times do |i|
        fork do
          ENV['TEST_ENV_NUMBER'] = i.to_s
          $0 = %[flatware worker #{i}]
          listen!
        end
      end
    end

    def listen
      trap('INT') {close!}
      time = Benchmark.realtime do
        fireable
        Sink.client.prime!
        report_for_duty
        fireable.until_fired task do |work|
          job = Marshal.load work
          log 'working!'
          # Cucumber.run job.id, job.args
          sleep
          log 'reporting results'
          Sink.finished job
          log 'ready for duty'
          report_for_duty
          log 'waiting'
        end
      end
      log time
    end

    private

    def close!
      log 'close! worker'
      log "sockets:", Flatware.instance_variable_get("@sockets").inspect
      Flatware.close!
      log 'closed'
      exit
    end

    def log(*args)
      Flatware.log *args
    end

    def fireable
      @fireable ||= Fireable.new
    end

    def task
      @task ||= Flatware.socket(ZMQ::REQ).tap do |task|
        task.connect Dispatcher::DISPATCH_PORT
      end
    end

    def report_for_duty
      task.send 'ready'
    end
  end
end
