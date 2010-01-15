# encoding: utf-8
module Watir
  class Browser
    include Container

    attr_reader :driver
    alias_method :wd, :driver # ensures duck typing with BaseElement

    class << self
      def start(url, browser = :firefox)
        b = new(browser)
        b.goto url

        b
      end
    end

    def initialize(browser, *args)
      case browser
      when Symbol, String
        @driver = Selenium::WebDriver.for browser.to_sym, *args
      when Selenium::WebDriver::Driver
        @driver = browser
      else
        raise ArugmentError, "expected Symbol or Selenium::WebDriver::Driver, got #{browser.class}"
      end

      @error_checkers = []
    end

    def inspect
      '#<%s:0x%x url=%s title=%s>' % [self.class, hash*2, url.inspect, title.inspect]
    end

    def goto(uri)
      uri = "http://#{uri}" unless uri.include?("://")

      @driver.navigate.to uri
      run_checkers

      url
    end

    def back
      @driver.navigate.back
    end

    def forward
      @driver.navigate.forward
    end

    def url
      @driver.current_url
    end

    def title
      @driver.title
    end

    def quit
      @driver.quit
    end

    def close
      @driver.quit
    end
    alias_method :quit, :close # TODO: close vs quit

    def clear_cookies
      @driver.manage.delete_all_cookies
    end

    def text
      # TODO: do this properly
      if @driver.bridge.browser == :firefox
        browserbot 'getVisibleText'
      else
        @driver.find_element(:tag_name, "body").text
      end
    end

    def html
      @driver.page_source
    end

    def refresh
      execute_script 'location.reload(true)'
    end

    def exist?
      true
    end

    def status
      execute_script "return window.status;"
    end

    def execute_script(script, *args)
      args.map! { |e| e.kind_of?(Watir::BaseElement) ? e.element : e }
      returned = @driver.execute_script(script, *args)

      if returned.kind_of? WebDriver::Element
        Watir.element_class_for(returned.tag_name).new(self, :element, returned)
      else
        returned
      end
    end

    def add_checker(checker = nil, &block)
      if block_given?
        @error_checkers << block
      elsif Proc === checker
        @error_checkers << checker
      else
        raise ArgumentError, "argument must be a Proc or block"
      end
    end

    def disable_checker(checker)
      @error_checkers.delete(checker)
    end

    def run_checkers
      @error_checkers.each { |e| e[self] }
    end

    #
    # @api private
    #

    def assert_exists
      true # TODO: assert browser is open
    end

  end # Browser
end # Watir
