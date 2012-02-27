module MCollective
  class UnixDaemon
    # Daemonize the current process
    def self.daemonize
      fork do
        Process.setsid
        exit if fork
        Dir.chdir('/tmp')
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen('/dev/null', 'a')

        yield
      end
    end

    def self.daemonize_runner
      UnixDaemon.daemonize do
        if pid
          begin
            File.open(pid, 'w') {|f| f.write(Process.pid) }
          rescue Exception => e
          end
        end

        runner = Runner.new(nil)
        runner.run
      end
    end
  end
end
