require 'thor'
module Flatware
  class CLI < Thor

    def self.processors
      @processors ||= `hostinfo`.match(/^(?<processors>\d+) processors are logically available\.$/)[:processors].to_i
    end

    def self.worker_option
      method_option :workers, aliases: "-w", type: :numeric, default: processors, desc: "Number of concurent processes to run"
    end

    class_option :log, aliases: "-l", type: :boolean, desc: "Print debug messages to $stderr"

    desc "mux", "splits your current tmux pane into worker panes. Runs workers in them."
    def mux
      processors.times do |env_number|
        command = <<-SH
          TEST_ENV_NUMBER=#{env_number} bundle exec ../../bin/flatware work && exit
        SH
        system <<-SH
          tmux send-keys -t `tmux split-window -h -P` "#{command}" C-m
        SH
      end
      system "tmux select-layout even-horizontal"
      dispatch
    end

    desc "dispatch", "fire up the dispatcher to distribute tests"
    def dispatch
      Dispatcher.start
    end

    desc "work", "request and perform work from a dispatcher"
    def work
     Worker.listen!
    end

    default_task :default
    worker_option
    desc "default", "parallelizes cucumber with default arguments"
    def default
      cucumber
    end

    worker_option
    desc "cucumber [CUCUMBER_ARGS]", "parallelizes cucumber with custom arguments"
    def cucumber(*)
      Flatware.verbose = options[:log]
      Worker.spawn workers
      jobs = Cucumber.extract_jobs_from_args args
      fork do
        log "dispatch"
        $0 = %[flatware dispatch]
        Dispatcher.start jobs
      end
      log "bossman"
      $0 = 'flatware sink'
      Sink.start_server jobs
      Process.waitall
    end

    worker_option
    desc "fan [COMMAND]", "executes the given job on all of the workers"
    def fan(*command)
      Flatware.verbose = options[:log]

      command = command.join(" ")
      puts "Running '#{command}' on #{workers} workers"

      workers.times do |i|
        fork do
          exec({"TEST_ENV_NUMBER" => i.to_s}, command)
        end
      end
      Process.waitall
    end


    desc "clear", "kills all flatware processes"
    def clear
      `ps -c -opid,command | grep flatware | cut -f 1 -d ' ' | xargs kill -6`
    end

    private

    def log(*args)
      Flatware.log(*args)
    end

    def workers
      options[:workers]
    end
  end
end
