class RadicalRetry
  class << self
    def perform_request(no_delay: false, &block)
      retries ||= 5
      block.call
    rescue Net::OpenTimeout, OpenURI::HTTPError, HTTPClient::ConnectTimeoutError, Errno::EPIPE, SocketError, OpenSSL::SSL::SSLError, Errno::ENOENT => exception
      if(retries -= 1) > 0
        exponential_pause(retries, no_delay)
        retry
      else
        raise exception
      end
    end
    alias_method :try, :perform_request

    private

    WAIT_TIMES = [2, 4, 8, 16, 32, 64]

    def exponential_pause(attempts, no_delay)
      return 0 if no_delay
      seconds = WAIT_TIMES[attempts- 1] || 64
      sleep(seconds)
    end
  end
end