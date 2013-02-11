#
# Escalation class for Sensu::Handler lib
# 
# Marcin Cabaj mcabaj@gmail.com
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'

class Escalation < Sensu::Handler

  def filter
        filter_disabled
        if @event['check']['status'] == 0
                filter_status0
        else
                filter_escalation
        end
        filter_silenced
  end

  def filter_disabled
        if ! @event['check']['escalation']
                bail 'handling disabled'
        end
  end

  def filter_status0
        @lev_array = []
        # check action for type:metric events
        bail 'Status is 0, as usual;) ..stop handling' if @event['action'] != 'resolve'
        escalation_scheme = @event['check']['escalation']
        settings['escalation'][escalation_scheme].each_key do |lev|
                start   = settings['escalation'][escalation_scheme][lev]['start']   || 1
                next if @event['occurrences'] < start
                @lev_array << lev
        end
        bail 'Do not handle.' if @lev_array.length == 0
  end

  def filter_escalation
        @lev_array = []
        escalation_scheme = @event['check']['escalation']
        settings['escalation'][escalation_scheme].each_key do |lev|

                start   = settings['escalation'][escalation_scheme][lev]['start']   || 1
                refresh = settings['escalation'][escalation_scheme][lev]['refresh'] || 3600

                next if @event['occurrences'] < start
                if settings['escalation'][escalation_scheme][lev].has_key?('stop')
                        next if @event['occurrences'] > settings['escalation'][escalation_scheme][lev]['stop']
                end
#               next unless (@event['occurrences']-start) % refresh.fdiv(@event['check']['interval']).to_i == 0 	# refresh in seconds
#               next unless (@event['occurrences']-start) % refresh == 0        					# refresh in occurrences
                next unless (@event['occurrences']-start) % refresh.fdiv(@event['check']['interval']).to_i == 0 # refresh w sekundach
                @lev_array << lev
        end
        bail 'Do not handle.' if @lev_array.length == 0
  end

  def handle
	puts 'Levels to notify are available with @lev_array array:'
	puts @lev_array
  end

end
