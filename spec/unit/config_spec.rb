#!/usr/bin/env ruby

require 'spec_helper'

module MCollective
  describe Config do
    describe "#loadconfig" do
      it "should not allow any path like construct for identities" do
        # Taken from puppet test cases
        ['../foo', '..\\foo', './../foo', '.\\..\\foo',
          '/foo', '//foo', '\\foo', '\\\\goo',
          "test\0/../bar", "test\0\\..\\bar",
          "..\\/bar", "/tmp/bar", "/tmp\\bar", "tmp\\bar",
          " / bar", " /../ bar", " \\..\\ bar",
          "c:\\foo", "c:/foo", "\\\\?\\UNC\\bar", "\\\\foo\\bar",
          "\\\\?\\c:\\foo", "//?/UNC/bar", "//foo/bar",
          "//?/c:/foo"
        ].each do |input|
          File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("identity = #{input}"))
          File.expects(:exists?).with("/nonexisting").returns(true)

          expect {
            Config.instance.loadconfig("/nonexisting")
          }.to raise_error('Identities can only match /\w\.\-/')
        end
      end

      it "should allow valid identities" do
        ["foo", "foo_bar", "foo-bar", "foo-bar-123", "foo.bar", "foo_bar_123"].each do |input|
          File.expects(:open).with("/nonexisting", "r").returns(StringIO.new("identity = #{input}"))
          File.expects(:exists?).with("/nonexisting").returns(true)
          PluginManager.stubs(:loadclass)
          PluginManager.stubs("<<")

          Config.instance.loadconfig("/nonexisting")
        end
      end
    end

    describe "#read_plugin_config_dir" do
      before do
        tmpfile = Tempfile.new("mc_config_spec")
        path = tmpfile.path
        tmpfile.close!

        @tmpdir = FileUtils.mkdir_p(path)
        @tmpdir = @tmpdir[0] if @tmpdir.is_a?(Array) # ruby 1.9.2

        @plugindir = File.join([@tmpdir, "plugin.d"])
        FileUtils.mkdir(@plugindir)

        Config.instance.set_config_defaults("")
      end

      it "should not fail if the supplied directory is missing" do
        Config.instance.read_plugin_config_dir("/nonexisting")
        Config.instance.pluginconf.should == {}
      end

      it "should skip files that do not match the expected filename pattern" do
        File.open(File.join([@tmpdir, "plugin.d", "foo.txt"]), "w") { }
        IO.expects(:open).with(File.join([@tmpdir, "plugin.d", "foo.txt"])).never

        Config.instance.read_plugin_config_dir(@plugindir)
      end

      it "should load the config files" do
        configfile = File.join([@tmpdir, "plugin.d", "foo.cfg"])
        File.open(configfile, "w") { }

        File.expects(:open).with(configfile, "r").returns([]).once
        Config.instance.read_plugin_config_dir(@plugindir)
      end

      it "should set config parameters correctly" do
        configfile = File.join([@tmpdir, "plugin.d", "foo.cfg"])

        File.open(configfile, "w") do |f|
          f.puts "bar = baz"
        end

        Config.instance.set_config_defaults(@tmpdir)
        Config.instance.read_plugin_config_dir(@plugindir)
        Config.instance.pluginconf.should == {"foo.bar" => "baz"}
      end

      it "should override main config file" do
        configfile = File.join([@tmpdir, "plugin.d", "foo.cfg"])
        servercfg = File.join(@tmpdir, "server.cfg")

        File.open(servercfg, "w") {|f| f.puts "plugin.foo.bar = foo"}

        PluginManager.stubs(:loadclass)

        Config.instance.loadconfig(servercfg)
        Config.instance.pluginconf.should == {"foo.bar" => "foo"}

        File.open(configfile, "w") do |f|
          f.puts "bar = baz"
        end

        PluginManager.delete("global_stats")
        Config.instance.loadconfig(servercfg)
        Config.instance.pluginconf.should == {"foo.bar" => "baz"}
      end
    end
  end
end
