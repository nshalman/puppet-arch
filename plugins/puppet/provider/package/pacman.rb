require 'puppet/provider/package'

Puppet::Type.type(:package).provide :pacman, :parent => Puppet::Provider::Package do
    desc "Provides packaging support for Arch Linux's pacman system."

    # Pacman returns a list of installed packages as "NAME VERSION"
    NV_FIELDS = [:name, :version]

    commands :pacman => "/usr/bin/pacman"

    defaultfor :operatingsystem => :arch

    confine :operatingsystem => :arch

    def self.instances
        packages=[]

        # list out all of the packages
        begin
            execpipe("#{command(:pacman)} -Q") { |process|
                # now turn each returned line into a package object
                process.each { |line|
                    hash = nv_to_hash(line)
                    packages << new(hash)
                }
            }
        rescue Puppet::ExecutionFailure
            raise Puppet::Error, "Failed to list packages"
        end

        return packages
    end

    def query
        begin
            output = pacman(["-Q", @resource[:name]])
        rescue Puppet::ExecutionFailure
            return nil
        end

        @property_hash.update(self.class.nv_to_hash(output))

        return @property_hash.dup
    end

    def install
        pacman(["-S", "--noconfirm", @resource[:name]])
    end

    def uninstall
        pacman(["-R", "--noconfirm", @resource[:name]])
    end

    def update
        self.install
    end

    def self.nv_to_hash(line)
        line.chomp!
        hash = {}
        NV_FIELDS.zip(line.split) { |f, v| hash[f] = v }
        hash[:provider] = self.name
        hash[:ensure] = hash[:version]
        return hash
    end

end

