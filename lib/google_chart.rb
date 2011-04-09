# stdlib requires
require 'rubygems'

# 3rd party rubygem requires
require 'htmlentities'
require 'open-uri' 
require 'cgi'


$:.unshift File.dirname(__FILE__) # For use/testing when no gem is installed

module WillWhim
  class GoogleChart
    VERSION = '1.0.0' 
    
    CHART_ENDPOINT = 'http://chart.apis.google.com/chart'
    
    SIMPLE_CODES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.split('')
    EXTENDED_CODES = SIMPLE_CODES + '-.'.split('')
    MAX_SIMPLE = SIMPLE_CODES.size-1
    MAX_TEXT = 100.0
    EXTENDED_SIZE =  EXTENDED_CODES.size
    MAX_EXTENDED = (EXTENDED_SIZE**2)-1 
    
    def self.simple_encoded(data)
      's:' +  self.simple_encoded_r(data)
    end
    
    def self.simple_encoded_r(data)
      if data.first.is_a? Array
        data.map {|datum| self.simple_encoded_r(datum)}.join(',')
      else
        data.map do |datum|
          if (datum < 0) or (datum > MAX_SIMPLE)
            '_'
          else
            SIMPLE_CODES[datum]
          end
        end.join('')
      end
    end
    
    def self.text_encoded(data)
      't:' + self.text_encoded_r(data)
    end
    
    def self.text_encoded_r(data) 
      if data.first.is_a? Array
        data.map {|datum| self.text_encoded_r(datum)}.join('|')
      else
        data.map do |datum|
          if (datum < 0) or (datum > MAX_TEXT)
            '-1'
          else
            (datum.is_a? Integer) ? datum.to_s : sprintf("%0.1f",datum)
          end
        end.join(',')
      end
    end

    def self.extended_encoded(data)
      'e:' + self.extended_encoded_r(data)
    end
    
    
    def self.extended_encoded_r(data)
      if data.first.is_a? Array
        data.map {|datum| self.extended_encoded_r(datum)}.join(',')
      else
        data.map do |datum|
          if (datum < 0) or (datum > MAX_EXTENDED)
            '__'
          else
            datum.divmod(EXTENDED_SIZE).map {|i| EXTENDED_CODES[i]}.join('')
          end
        end.join('')
      end
    end
    
    # [100, 200, 100, 200] 100, 200, 50 -> [0, 50, 0, 50] 
    #  (n-min) = [0, 100, 0, 100]
    #  * 50/100 = [0, 50, 0, 50] 
    # [100, 120, 180] 100, 180, 100 -> [0, ,100]    range = 80 120
    # [100, 200] newmin: 50 -> 50, 150; 0 -> 0, 100
    def self.translate(data, min, newmin)
      return data.map {|r| GoogleChart.translate(r, min, newmin)} if data.first.is_a?(Array)
      diff = min-newmin
      data.map{|datum| datum - diff}
    end
    
    def self.scale(data, range, newrange)
      return data.map {|r| GoogleChart.enbiggen(r, min, newmin)} if data.first.is_a?(Array)
      diff = Float(newrange)/range
      data.map{|datum| datum * diff}
    end
    
    def self.range(data)
      flat = data.flatten
      min = flat.min
      max = flat.max
      [min, max, (max-min).abs]
    end

    def self.fit(data, min, max, range, new_min, new_max, new_range)
      return data if ((range <= new_range) and (max <= new_max)) # no fitting needed
      return GoogleChart.translate(data, min, new_min) if (range <= new_range) # just translate
      return GoogleChart.scale(GoogleChart.translate(data, min, new_min), range, new_range) # translate & scale
    end
    
    def self.guess_encoded(data)
      min,max,range = self.range(data)
      return GoogleChart.simple_encoded(GoogleChart.fit(data, min, max, range, 0, MAX_SIMPLE, MAX_SIMPLE)) if range <= MAX_SIMPLE
      return GoogleChart.text_encoded(GoogleChart.fit(data, min, max, range, 0, MAX_TEXT, MAX_TEXT)) if range <= MAX_TEXT
      GoogleChart.extended_encoded(GoogleChart.fit(data,min, max, range, 0, MAX_EXTENDED, MAX_EXTENDED)) # otherwise
    end
    
    def encode_key_value(key, data)
      case key
      when :chd: GoogleChart::encode_data(data, data_encoding)
      else CGI.escape(data.to_s)
      end
    end
    
    def self.encode_data(data, encoding=:guess)
       case encoding
       when :none, :identity: data
       when :guess,false: GoogleChart::guess_encoded(data)
       when :simple, :s: GoogleChart::simple_encoded(data)
       when :text, :t: GoogleChart::text_encoded(data)
       when :extended, :e: GoogleChart::extended_encoded(data)
       else
         raise TypeError, "invalid data encoding: #{encoding.inspect}"
       end
     end
    
    attr_accessor :options
    attr_accessor :data_encoding
    
    def initialize(chart_type, size)
      @options = Hash.new
      @options[:cht] = chart_type
      @options[:chs] = size
    end
    
    def [](key)
      @options[key]
    end
    
    def []=(key,value)
      @options[key]=value 
    end
    
    
    def to_url
      coder = HTMLEntities.new
      CHART_ENDPOINT + "?" + @options.map{|k,v| "#{k}=#{encode_key_value(k, v)}"}.join('&')
    end
    
    alias to_uri to_url
    
    def to_img(alt=false)
      alt ||= (@options[:t]  or 'Chart')
      coder = HTMLEntities.new
      "<img src=\"" + CHART_ENDPOINT + "?" + @options.map{|k,v| "#{k}=#{encode_key_value(k, v)}"}.join('&amp;') + "\" alt=\"#{coder.encode(alt)}\"/>"
    end
    
    def add_data(data, encoding=:guess)
      @data_encoding = encoding
      @options[:chd] = data
      self
    end
    
    def to_file(path)
      File.open(path, 'w+').write(open(to_url).read)
    end
  end

end
