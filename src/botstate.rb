# Maintains state for the bot.
class BotState

  # Sets the full host of the bot.
  #
  # @param [String] The value of the fullhost.
  # @return [nil] Nil
  def fullhost=(value)
    @fullhost = value
    split = value.split('@')
    @host = split[1]
    split = split[0].split('!')
    @nick = split[0]
    @user = split[1]
  end
  
  attr_reader :fullhost
  attr_accessor :nick, :host, :user
end

