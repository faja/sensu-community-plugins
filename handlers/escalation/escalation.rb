#
# Escalation class for Sensu::Handler lib
# 
# Marcin Cabaj mcabaj@gmail.com
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'

class Escalation < Sensu::Handler

  def filter
    if @event['check']['name'] == 'keepalive'
      @escalation_scheme = 'keepalive'
      @event['check']['interval'] = 30
    else
      filter_disabled
    end
    if @event['check']['status'] == 0
      filter_status0
    else
      filter_escalation
    end
    filter_silenced
  end

  def filter_disabled
    if ! @event['check']['escalation']
      bail 'Handling disabled. No "escalation" key in check config'
    else
      @escalation_scheme = @event['check']['escalation']
    end
  end

  def filter_status0
    # don't handle metric type events
    exit 0 if @event['action'] != 'resolve'
    @lev_array = []
    settings['escalation'][@escalation_scheme].each_key do |lev|
      start = settings['escalation'][@escalation_scheme][lev]['start'] || 1
      next if @event['occurrences'] < start
      @lev_array << lev
    end
    bail 'Handling stopped due to escalation settings' if @lev_array.length == 0
  end

  def filter_escalation
    @lev_array = []
    settings['escalation'][@escalation_scheme].each_key do |lev|
      start = settings['escalation'][@escalation_scheme][lev]['start'] || 1
      refresh = timeparser(settings['escalation'][@escalation_scheme][lev]['refresh']) || 3600
      # "start" escalation
      next if @event['occurrences'] < start
      # "how many times" escalation
      if settings['escalation'][@escalation_scheme][lev].has_key?('stop')
        next unless (@event['occurrences'].to_i-start.to_i)*@event['check']['interval'].to_i < settings['escalation'][@escalation_scheme][lev]['stop'].to_i*refresh.to_i
      end
      # "refresh" escalation
      if refresh > @event['check']['interval']
        next unless (@event['occurrences']-start) % refresh.fdiv(@event['check']['interval']).to_i == 0
      end
      @lev_array << lev
    end
    bail 'Handling stopped due to escalation settings' if @lev_array.length == 0
  end

  def handle
    puts 'Levels to notify are available with @lev_array array:'
    puts @lev_array
    puts 'Escalation scheme is available with @escalation_scheme variable:'
    puts @escalation_scheme
  end

  def timeparser(time)
    tokens = {
      "m" => (60),        "M" => (60),
      "h" => (60*60),     "H" => (60*60),
      "d" => (24*60*60),  "D" => (24*60*60)
    }
  
    time.to_s.scan(/(\d+)(\w)/) do |amount,measure|
      return amount.to_i if ! measure or ! tokens[measure]
      return amount.to_i*tokens[measure]
    end
  end
end

