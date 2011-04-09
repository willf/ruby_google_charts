require File.dirname(__FILE__) + '/test_helper'

describe "Google Chart tests"  do
  it 'should be able to create a chart instance' do
    lambda do                 
      GoogleChart.new(:v, '200x300')
    end.should_not raise_error
  end
  
  it 'should be able to do simple encoding' do
    GoogleChart.simple_encoded([0,19,27,53,61]).should == "s:ATb19"
  end

  it 'should be able to do simple encoding of multiple arrays' do
    GoogleChart.simple_encoded([[0,19,27,53,61],[0,19,27,53,61]]).should == "s:ATb19,ATb19"
  end
  
  it 'should handle missing data in simple encoding' do 
    GoogleChart.simple_encoded([-1, 0,19,27,53,61,99990]).should == "s:_ATb19_"
  end

  it 'should be able to do text encoding' do
    GoogleChart.text_encoded([1.0,2,3]).should == "t:1.0,2,3"
  end

  it 'should be able to do text encoding of multiple arrays' do
     GoogleChart.text_encoded([[1,2,3],[Math::PI,Math::E,Math::PI*Math::E]]).should == "t:1,2,3|3.1,2.7,8.5"
   end

  it 'should handle missing data in text encoding' do 
    GoogleChart.text_encoded([-1, 1, 101]).should == "t:-1,1,-1"
  end 

  it 'should be able to do extended encoding' do
    GoogleChart.extended_encoded([0,63, 127, 4095]).should == "e:AAA.B..."
  end

  it 'should be able to do extended encoding of multiple arrays' do
     GoogleChart.extended_encoded([[0,63, 127, 4095],[0,63, 127, 4095]]).should == "e:AAA.B...,AAA.B..."
   end

  it 'should handle missing data in text encoding' do 
    GoogleChart.extended_encoded([-1, 1, 4096]).should == "e:__AB__"
  end
  
  it 'should make proper guesses on ranges' do
    GoogleChart.range([1,2,3]).should == [1,3,2] 
    GoogleChart.range([1]).should == [1,1,0]
  end
  
  it 'should guess a simple encoding for small data lists' do
    GoogleChart.guess_encoded([0,1,2,3]).should == GoogleChart.simple_encoded([0,1,2,3])
  end
  
  it 'should translate to a simple encoding for small data lists' do
    GoogleChart.guess_encoded([61,62,63,64]).should == GoogleChart.simple_encoded([0,1,2,3])
  end
  
  it 'should guess a text encoding for ranges over 61 and under 100' do
    GoogleChart.guess_encoded([0,100]).should == GoogleChart.text_encoded([0,100])
  end
  
  it 'should translate a text encoding for ranges under 100 with a max over 100' do 
    GoogleChart.guess_encoded([1,101]).should == GoogleChart.text_encoded([0,100])
  end
  
  it 'should guess an extended encoding for ranges over 100 with max < MAX_EXTENDED' do
    GoogleChart.guess_encoded([0, GoogleChart::MAX_EXTENDED]).should == GoogleChart.extended_encoded([0, GoogleChart::MAX_EXTENDED])
  end

  it 'should translate an extended encoding for ranges over 100 with max > MAX_EXTENDED' do
    GoogleChart.guess_encoded([0+10, GoogleChart::MAX_EXTENDED+10]).should == GoogleChart.extended_encoded([0, GoogleChart::MAX_EXTENDED])
  end
  
  it 'should scale an extended encoding for other big ranges' do 
    GoogleChart.guess_encoded([0, 2*(GoogleChart::MAX_EXTENDED)]).should == GoogleChart.extended_encoded([0, GoogleChart::MAX_EXTENDED])    
  end

  it 'should translate and scale an extended encoding for other big ranges' do 
    GoogleChart.guess_encoded([0+10, 2*(GoogleChart::MAX_EXTENDED)+10]).should == GoogleChart.extended_encoded([0, GoogleChart::MAX_EXTENDED])    
  end  
  
  
  it 'should create a proper chart url' do
    cht = GoogleChart.new(:lc,'200x100')
    cht.add_data([10,20,30,40,50])
    cht[:chl]="Texas A & M"
    test = URI.parse(cht.to_url)
    test.scheme.should == 'http'
    test.host.should == 'chart.apis.google.com'
    test.port.should == 80
    test.path.should == "/chart"
    options = {}; test.query.split('&').each{|opt| k,v = opt.split('='); options[k]=v}
    options["cht"].should == "lc"
    options["chl"].should == CGI.escape("Texas A & M")
    # options["chd"].should == "t:10.0,20.0,30.0,40.0,50.0"
  end
 
  it 'should create a proper IMG tag' do
    cht = GoogleChart.new(:lc,'200x100')
    cht.add_data([10,20,30,40,50])
    cht[:chl]="Texas A & M"  
    doc = REXML::Document.new(cht.to_img('Texas A & M Chart'))
    test = URI.parse(doc.elements[1].attributes['src'])
    test.scheme.should == 'http'
    test.host.should == 'chart.apis.google.com'
    test.port.should == 80
    test.path.should == "/chart"
    options = {}; test.query.split('&').each{|opt| k,v = opt.split('='); options[k]=v}
    options["cht"].should == "lc"
    options["chl"].should == CGI.escape("Texas A & M")
    # options["chd"].should == "t:10.0,20.0,30.0,40.0,50.0"
    doc.elements[1].attributes['alt'].should == "Texas A & M Chart" # xml parsed ...
  end
end
