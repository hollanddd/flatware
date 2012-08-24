module Flatware
  class Fireable
    def initialize
      @die = Flatware.socket(ZMQ::SUB).tap do |die|
        die.connect 'ipc://die'
        die.setsockopt ZMQ::SUBSCRIBE, ''
      end
    end

    attr_reader :die

    def until_fired(sockets=[], &block)
      while messages = ready_messages(sockets)
        Flatware.log messages
        break if messages.include? 'seppuku'
        messages.each &block
      end
    ensure
      Flatware.close
    end

    private

    def ready_messages(sockets)
      ZMQ.select(Array(sockets) + [die]).flatten.compact.map(&:recv)
    rescue Interrupt
      Flatware.log(:interupted!)
      []
    end

  end
end
