#!/usr/bin/env ruby

require 'tty-prompt'
require 'rest-client'
require 'hpricot'

def find_date_values(html, date)
  doc = Hpricot(html)
  requested_indexes = doc.search('//table[@class="memorable"]/tr[2]/td')[1..-2].map { |e| e.children.length == 1 ? e.innerText.gsub(/[[:space:]]/, '') : '?' }.join.gsub(/\/(AA)?/, '').split(//).each_with_index.map { |a, i| a == '?' ? i : nil }.compact
  requested_indexes.map { |i| date[i] }
end

def find_balance(html)
  doc = Hpricot(html)
  doc.search('//*[@id="availableBalance"]').inner_text.strip
end

prompt = TTY::Prompt.new

security_result = `security find-internet-password -s cartaodascaper -g 2>&1`

if security_result[/could not be found/]
  username = prompt.ask('What is the user name?') do |q|
    q.required true
    q.validate /\A\S+\Z/
  end

  password = prompt.mask('What is the password?') do |q|
    q.required true
  end

  date = prompt.mask('What are the digits for the date? (DDMMYY)?') do |q|
    q.required true
    q.validate /\d{6}/
  end

  `security add-internet-password -a "#{username}" -s cartaodascaper -w "#{password}#{date}"`
else
  account = security_result.split("\n").find { |line| line[/\"acct\"/] }.match(/=\"(.*)\"/)[1]
  password_date = security_result.split("\n")[0].match(/\"(.*)\"/)[1]
  password = password_date[0..-7]
  date = password_date[-6..-1]
end

$stderr.puts "Using stored account '#{account}'…"
# puts password
# puts date

response1 = RestClient.post(
  'https://sites.prepaytec.com/chopinweb/scareMyLogin.do?loc=pt',
  {
    :page => '1',
    :customerCode => '19151415',
    :agentCode => '',
    :username => 'carlosefonseca',
    :password => 'weqFos-zokgiq-5pubfu',
    'submit.x' => '81',
    'submit.y' => '8'
  },
  { :headers => {
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Content-Type' => 'application/x-www-form-urlencoded',
    'Origin' => 'https://sites.prepaytec.com',
    'Accept-Language' => 'en-us',
    'Host' => 'sites.prepaytec.com',
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.1 Safari/605.1.15',
    'Referer' => 'https://sites.prepaytec.com/chopinweb/scareMyLogin.do?customerCode=19151415&loc=pt&brandingCode=myscare_pt&org.apache.catalina.filters.CSRF_NONCE=614F4605624AECCF95FD612B646B472A',
    'Accept-Encoding' => 'gzip, deflate, br',
    'Connection' => 'keep-alive'
  } }
)

values = find_date_values(response1.body, date)

begin
  response2 = RestClient.post(
    'https://sites.prepaytec.com/chopinweb/scareMyLogin.do?loc=pt',
    {
      'page' => '2',
      'customerCode' => '19151415',
      'agentCode' => '',
      'securityDigit1' => values[0],
      'securityDigit2' => values[1],
      'securityDigit3' => values[2],
      'submit.x' => '74',
      'submit.y' => '11'
    },
    { :headers => {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Origin' => 'https://sites.prepaytec.com',
      'Accept-Language' => 'en-us',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.1 Safari/605.1.15',
      'Referer' => 'https://sites.prepaytec.com/chopinweb/scareMyLogin.do?loc=pt',
      'Accept-Encoding' => 'gzip, deflate, br',
      'Connection' => 'keep-alive'
    },
      :cookies => response1.cookies }
  )
rescue => exception
  begin
    # RestClient only follows redirects for GET/HEAD requests.
    exception.response.follow_redirection
  rescue => exception
    # And there are two redirects until reaching the home page.
    response3 = exception.response.follow_redirection
    puts find_balance(response3.body)
  end
end
