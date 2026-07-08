# Home Assistant

Running my HASS instance inside docker, because I am using quite a lot of HACS integrations, and configuring all of this in nix would be extremely painful.

## Problems during backup restore

When I tried to copy all files from a previous backup into the folder of home-assistant, I can only presume something went wrong with the initialisation of the system.
HACS was not registered at all and i was not able to bring it up.

Tried again with empty configs, HACS worked.

Restored backup once more, it worked fine this time.

No clue what was wrong.
