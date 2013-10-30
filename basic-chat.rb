#!/usr/bin/env ruby
#basic-chat.rb

require 'rubygems' # or use Bundler.setup
require 'eventmachine'
require 'obscenity'

class BasicChat < EM::Connection

  @@connected_clients = Array.new

  def post_init
  	@username = nil
  	puts "Someone joined the chat..."
    query_name
  end

  def unbind
  	@@connected_clients.delete(self)
  	puts "#{@username} has left the chat."
    @@connected_clients.each { |c| c.send_data("#{@username} has left the chat.\n") unless c == self }
  end

  def username_entered?
  	!@username.nil? && !@username.empty?
  end

  def receive_data(data)
  	if username_entered?
  	  message_handler(data.strip)
  	else
  	  name_handler(data.strip)
  	end
  end

  def query_name
  	send_data("[BasicChat] Enter your name: ")
  end

  def message_handler(data)
  	if data.strip == "/exit"
  	  send_data("You have left the chat room.\n")
      close_connection
  	else
      send_message data
	  end
  end

  def send_message data
    censor(data)
    puts "#{@username}: #{data}\n"
    @@connected_clients.each { |c| c.send_data("#{@username}: #{data}\n") unless c == self }
    send_data("[BasicChat] You're the only one in the room.") if @@connected_clients.length <= 1
  end

  def name_handler(name)
  	@username = name
  	@@connected_clients.push(self)
  	puts "[BasicChat] #{@username} has joined the chat."
    @@connected_clients.each { |c| c.send_data("[BasicChat] #{@username} has joined the chat.\n") unless c == self }
    self.send_data("[BasicChat] Welcome to the chat room, #{@username}. Type a message and hit [enter] to send the message. You can leave by typing \"/exit\" and hitting [enter].")
  end

  def censor(data)
    Obscenity.sanitize(data)
  end

end

Obscenity.configure do |config|
  config.blacklist   = ["fuck", "shit"]
  config.whitelist   = ["safe", "word"]
  config.replacement = :stars
end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("0.0.0.0", 10000, BasicChat)
end