if FileTest.exists?("/etc/arch-release")
  Facter.add(:operatingsystem) do
      confine :kernel => :linux
      setcode do
        "Arch"
      end    
  end
end