#!/usr/bin/env ruby
#client.rb

require 'rubygems'
require 'eventmachine'

class Echo < EM::Connection
  attr_reader :queue

  def initialize(q)
    @queue = q

    cb = Proc.new do |msg|
      send_data(msg)
      q.pop &cb
    end

    q.pop &cb
  end

  def post_init
  end

  def receive_data(data)
    puts data
  end
end

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :queue

  def initialize(q)
    @queue = q
  end

  def receive_line(data)
    @queue.push(data)
  end
end

EM.run {
  q = EM::Queue.new

  EM.connect('0.0.0.0', 10000, Echo, q)
  EM.open_keyboard(KeyboardHandler, q)
}