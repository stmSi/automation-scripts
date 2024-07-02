#!/bin/bash
sudo evdev-joystick --evdev /dev/input/js0 --deadzone 43000 --axis 0
sudo evdev-joystick --evdev /dev/input/js0 --deadzone 43000 --axis 1

