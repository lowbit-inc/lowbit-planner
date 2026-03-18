#!/bin/bash

# Configs can be set at
# - Built-in defaults (internal lib)
# - Global config file (/etc/lowbit-planner.cfg)
# - User-specific config file (˜/.lowbit-planner/plan.cfg)
# - Environment Variables (LBPLAN_*)
# - Command-line arguments (--arg)

##############
# Properties #
##############

config_timezone=null
config_noprompt=false
config_nocolor=false
config_debug=false

###########
# Methods #
###########

# - [ ] check config
# - [ ] create config
# - [ ] read config