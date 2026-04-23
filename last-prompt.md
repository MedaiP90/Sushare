you were working on this flutter app: [@sushare-flutter-prompt.md](file:///home/leonardo/Documenti/Personal_projects/Sushare/sushare-flutter-prompt.md) 
it is time to work on the session share with other users.

use socketio for realtime communication and messages exchange. remove the check for locked orders when more users connected, it is unnecessary.

the info to be excenged between host and guests and viceversa:
- restaurant -> update the guests or the host if they do not have it
- restaurant menu -> update the guests or the host if they do not have it
- users info: username, first and last name, profile picture
- personal order -> used for merging
- make sure not to merge multiple times the orders when someone update theirs
- send order command
- new round command

the new session should be auto-saved (including the connection info) in the guests. all updates should immediately be showed in the relative lists.

the host will be an hub for all the guests and its goal is to collect the order info and forward the updates to the guests too. it has to track the connected clients for info forwarding.

remove the group section from the guests, it is a function available to the host only. remember that the checklist is meant for the current user only, do not add the items from other users to it.

if a guest try to connect to a non active host or to a non active session the app must make the session temporary frozen with a message to warn the session is not reachable momentarely
