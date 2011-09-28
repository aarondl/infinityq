require 'resolv'

# Resolver factory resolves an ip based on environment settings
class ResolverFactory
  # Uses reverse dns to retrieve an ip depending on
  # the environment
  #
  # @param [String] The ip address to reverse dns
  # @return [String] The hostname if it was possible to obtain
  def self.resolve(ip)
    return nil if ip.nil?
    return 'irc.nuclearfallout.net' if ENV['INF_ENV'] == 'TEST'
    return Resolv.getname ip
  end
end

