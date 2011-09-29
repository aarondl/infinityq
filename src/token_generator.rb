require 'uuid'

class TokenGenerator
  # Generates a randomized token to uniquely identify
  # event registrations.
  #
  # @return [Symbol] A randomized unique token.
  def self.generate_token
    @@uuid ||= UUID.new
    guid = @@uuid.generate :compact
    while guid.length >= 16 && guid.match(/^[0-9]/)
      guid = guid[1...guid.length]
    end
    return generate_token if guid.length < 16
    return guid.to_sym
  end  
end

