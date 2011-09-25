require 'resolv'

class ResolverFactory
  def self.resolve(ip)
    return nil if ip.nil?
    return 'irc.nuclearfallout.net' if ENV['RBB_ENV'] == 'TEST'
    return Resolv.getname ip
  end
end
