#/bin/zsh
# Version 1.0
# Restarts the processes controlling the Touch Bar, use if Touch Bar is unresponsive

sudo pkill TouchBarServer
sudo killall ControlStrip
