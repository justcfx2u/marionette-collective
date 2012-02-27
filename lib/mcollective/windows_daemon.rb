require 'win32/daemon'

module MCollective
  class WindowsDaemon < Win32::Daemon
    def self.daemonize_runner
      WindowsDaemon.mainloop
    end

    def service_main
      Log.debug("Starting Windows Service Daemon")

      while running?
        runner = Runner.new(nil)
        runner.run
      end
    end

    def service_stop
      Log.info("Windows service stopping")
      PluginManager["connector_plugin"].disconnect
      exit!
    end
  end
end
