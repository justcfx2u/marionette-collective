require 'optparse'

opt = OptionParser.new

basedir = ENV["BASEDIR"]
libdir = ENV["RUBYLIB"]
mcollectived = ENV["MCOLLECTIVED"]
ruby_path = ENV["RUBY"]
configfile = ENV["SERVER_CONFIG"]

options = {:name    => "mcollectived",
           :display_name => "The Marionette Collective",
           :description => "Puppet Labs server orcahastration framework",
           :command => '%s -I"%s" -- "%s" --config "%s"' % [ ruby_path, libdir, mcollectived, configfile ]}

action = false

opt.on("--install", "Install service") do
  action = :install
end

opt.on("--uninstall", "Remove service") do
  action = :uninstall
end

opt.on("--name NAME", String, "Service name (#{options[:name]})") do |n|
  options[:name] = n
end

opt.on("--description DESCRIPTION", String, "Service description (#{options[:description]})") do |v|
  options[:description] = v
end

opt.on("--display NAME", String, "Service display name (#{options[:display_name]})") do |n|
  options[:display_name] = n
end

opt.on("--command COMMAND", String, "Service command (#{options[:command]})") do |c|
  options[:command] = c
end

opt.parse!

abort "Please choose an action with --install or --uninstall" unless action

require 'rubygems'
require 'win32/service'

include Win32

case action
  when :install
    Service.new(
      :service_name => options[:name],
      :display_name => options[:display_name],
      :description => options[:description],
      :binary_path_name => options[:command],
      :service_type => Service::SERVICE_WIN32_OWN_PROCESS
    )

    puts "Service %s installed" % [options[:name]]

  when :uninstall
    Service.stop(options[:name]) unless Service.status(options[:name]).current_state == 'stopped'

    while Service.status(options[:name]).current_state != 'stopped'
      puts "Waiting for service %s to stop" % [options[:name]]
      sleep 1
    end

    Service.delete(options[:name])

    puts "Service %s removed" % [options[:name]]
end
