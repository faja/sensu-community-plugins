# Escalation for sensu handlers

## Configuration
### settings.escalation.json
Put this file to conf.d dir and modify or add escalation scheme.
You can use escalation scheme in check configuration file then ("escalation":"scheme_name") to escalate of handling event.

Escalation schemes contain one or more escalation levels. Escalation level keys:
* start - number of occurrences when to start handle events for this level, [default=1]
* stop - how many times event will be handle, [default=infinity]
* refresh - frequency of handling events (in seconds) [default=3600]

e.g. for scheme1 below, 
* user1 will be notified only 3 times with 30minutes refresh, starting with first event occurence
* group1 will be notified every 3 hour, starting with 360th event occurence

```
{
        "escalation": {
        
                "keepalive":{
                        "lev_1":{
                                "refresh":"1h",
                                "to":"user1@example.com, user2@example.com"
                        }
                },
                
                "scheme1":{
                        "lev_1":{
                                "start":1,
                                "stop":3,
                                "refresh":"30m",
                                "to":"user1@example.com"
                        },
                        "lev_2":{
                                "start":360,
                                "refresh":"3h",
                                "to":"group1@example.com"
                                }
                        }

        }
}
```

### check config
Add custom key "escalation" to your check configuration
```
"escalation":"scheme_name"
```

## Usage
Modify your handler to use Escalation class, eg:
```
require_relative 'escalation'
class Mailer < Escalation
```
then there are level names in @lev_array, you can can access "to" key (or any other defined) to find out to whom send notification, eg:
```
def handle
        ...
        @len_array.each do |lev|
                mail_to = settings['escalation'][@escalation_scheme][lev]['to']
        ...
        end
end
