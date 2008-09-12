# Manage Arch services.  Start/stop is the same as InitSvc, but enable/disable
# is special.  Requires Augeas
require 'augeas.rb'

Puppet::Type.type(:service).provide :arch, :parent => :init do
    desc "Arch's form of ``init``-style service
        management; modifies /etc/rc.conf for service enabling and disabling."

    begin
        require "augeas"
    rescue Exception => e
        fail ("The Arch Linux service provider requires the augeas-ruby bindings to be installed")
    end

    defaultfor :operatingsystem => :arch

    confine :operatingsystem => :arch

    def self.defpath
        superclass.defpath
    end

    def disable
        begin
            output = update :del, @resource[:name], :default
        rescue Puppet::ExecutionFailure
            raise Puppet::Error, "Could not disable %s: %s" %
                [self.name, output]
        end
    end

    def enabled?
        begin
            Augeas.open("/","",0).match("/files/etc/rc.conf/DAEMONS/*").map { |x| aug.get(x) == @resource[:name] }.inject { |result, n| result or n }
        rescue Puppet::ExecutionFailure
            return :false
        end

        line = output.split(/\n/).find { |l| l.include?(@resource[:name]) }

        return :false unless line

        # If it's enabled then it will print output showing service | runlevel
        if output =~ /#{@resource[:name]}\s*|\s*default/
            return :true
        else
            return :false
        end
    end

    def enable
        begin
            output = update :add, @resource[:name], :default
        rescue Puppet::ExecutionFailure
            raise Puppet::Error, "Could not enable %s: %s" %
                [self.name, output]
        end
    end
end

# $Id $
