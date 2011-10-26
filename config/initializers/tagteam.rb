ROBOT_USER_AGENT = "tagteam social RSS aggregrator 0.1: http://github.com/berkmancenter/taghub"
RSS_GENERATOR = "tagteam social RSS aggregrator"

# If a feed has changed, schedule it to be spidered again within this interval.
MINIMUM_FEED_SPIDER_INTERVAL = 15.minutes

# If a feed has not changed within this interval, back off for SPIDER_DECAY_INTERVAL.
SPIDER_UPDATE_DECAY = 2.hours

# After SPIDER_UPDATE_DECAY has been reached, extend the next spidering event out by this interval.

SPIDER_DECAY_INTERVAL = 1.hour

MAXIMUM_FEED_SPIDER_INTERVAL = 1.day
