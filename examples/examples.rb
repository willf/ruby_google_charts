require 'rubygems'
require 'erb'

require File.dirname(__FILE__) + '/../lib/google_chart'
include WillWhim   

@charts = []
c = GoogleChart.new(:lc, '500x200')
c.add_data [[0,30,60,70,90,95,100],[20,30,40,50,60,70,80]], :text
c[:chl]='Test Chart Two Data lines|(Given encoding)'
@charts << c

c = GoogleChart.new(:lc, '500x200')
c.add_data [[0,30,60,70,90,95,100],[20,30,40,50,60,70,80]]
c[:chl]='Test Chart Two Data lines|(Guess encoding)'
@charts << c

c = GoogleChart.new(:lxy, '500x200')
c.add_data [[0,30,60,70,90,95,100],[20,30,40,50,60,70,80]], :text
c[:chl]= 'The Price of Tea|Foot Size'
@charts << c

c = GoogleChart.new(:p, '500x200')
c.add_data [25, 25, 30, 10, 5], :text
c[:chl]= 'You|Me|Them|Us|It'
c[:chtt]='The Division of Labor'
@charts << c


c = GoogleChart.new(:p3, '500x200')
c.add_data [25, 25, 30, 10, 5], :text
c[:chl]= 'You|Me|Them|Us|It'
c[:chtt]='The Division of Labor'
@charts << c
def nrand(n,max)
  r = []
  n.times{ r<<rand(max)+1}
  r
end

c = GoogleChart.new(:v, '300x300')
c.add_data [100,80,60,30,30,30,10], :text
c[:chdl] = 'Yours|Mine|Ours'
@charts << c

c = GoogleChart.new(:bvs, '300x200')
c.add_data [100,80,60,30,30,60,80,75], :text
c[:chtt] = 'Pct who understand Charts'
c[:chl] = '00|01|02|03|04|05|06|07'  
@charts << c

c = GoogleChart.new(:s, '300x300')
c.add_data [nrand(20,61), nrand(20,61), nrand(20,61)], :simple  
c[:chl]= 'The Price of Tea|Foot Size'
c[:chtt]='Random Scatter Plot'
c[:chm]=20
@charts << c

years = [1958,1959,1960,1961,1962,1963,1964,1965,1966,1967,1968,1969,1970,1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,1981,1982,1983,1984,1985,1986,1987,1988,1989,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007]
budget = [0.488,0.781,2.145,3.879,6.554,12.767,20.587,24.795,26.820,24.798,20.664,17.537,14.616,12.356,11.787,10.910,9.790,9.111,9.356,9.297,8.798,8.540,8.966,9.089,9.436,9.973,10.050,9.996,9.960,9.940,11.540,13.506,14.714,15.735,15.310,15.301,14.351,13.692,13.882,14.067,13.193,12.999,12.618,12.884,13.305,13.158,13.452,13.201,13.111,13.007]
c = GoogleChart.new(:bvs,'1000x200')
c.add_data(budget)               
c[:chbh] = (1000/years.size)-4
c[:chtt] = 'NASA Budget per year'
c[:chf]= 'bg,s,efefef'
c[:chl]= years.collect{|year| "'"+year.to_s[2,2]}.join('|')
@charts << c

template = %{
    <html>
      <head><title>Charts!</title></head>
      <body>
       <h1><%= @charts.size %> Google Chart Examples</h1>
        <% @charts.each_with_index do |chart,i| %>
          <h3><%=  chart[:chtt] or chart[:chl] or 'Chart ' + (i+1).to_s %>
          <p><a href="<%= chart.to_url %>">link</a><br />
          <%= chart.to_img %> 
          </p>
          <hr />
        <% end %>
      </body>
    </html>
  }.gsub(/^  /, '')
  
rhtml = ERB.new(template)
rhtml.run()
