# Escalation for sensu handlers

## Configuration files
### settings.escalation.json
Modify or add escalation scheme, you can use escalation scheme in check configuration file then ("escalation":"scheme_name").
Escalation schemes contain one or more escalation levels. Escalation level keys:
* start - number of occurrences when to start handle events for this level, [default=1] 
* stop - number of occurrences, after when to stop handle events for this level, [default=end of the world]
* refresh - frequency of handling events [default=3h]

eg. 
We have check with interval 60. We want to send notification to user1 for first 3 hours, every 1 hour.
And after 3 hours we want to send the same notification to group1, every 3 hour.
```
{
        "escalation": {
                "scheme1":{
                        "lev_1":{
                                "start":1,
                                "stop":10800,
                                "refresh":3600,
                                "to":"user1@example.com"
                                },
                        "lev_2":{
                                "start":10800,
                                "refresh":10800,
                                "to":"group1@example.com"
                                }
                        }

        }
}
```

### check config
Add custom key "escalation" to your check configuration
```
"escalation":"scheme1"
```

## Usage
Modify your handler to use Escalation class, eg:
```
require './escalation'
class Mailer < Escalation
```
then there are level names in @lev_array, you can can access "to" key (or any other defined) to find out to whom send notification, eg:
```
def handle
        ...
        @len_array.each do |lev|
                mail_to = settings['escalation'][@event['check']['escalation']][lev]['to']
        ...
        end
end
