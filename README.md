# LYCORIS-ECLYPSE
A project centered about the CC:Tweaked mod, that I plan to deploy on my server.
All are aimed to be open-source, personal tools to make community life easier and simplify everyday tasks
##### It currently contains :
- distress beacon
- encrypted chat app

##### And will soon include :
- Full Advanced Pocket Computer OS (dubbed LycorisOS)
- The RADIATA, optional centralized serveur for LycorisOS
- Centralized encrypted chat app
- Centralized location sharing app
- Delivery system
- Miscellaneous apps like 
    - Storage summary
    - Remote redstone control
    - And more.....

#### Philosophy :
The aim of this project is, as said above, to provide users with tools to make communicating, coordinating, and sharing informations easier, alongside controlling several apps to make things easier, like controlling farms, or whatever you may want.

#### Parts of the environment (or what's currently developped at least)

##### **Distress beacons**

`beacon.lua` can be used to turn a pocket computer (if equipped with an Ender Modem) into a deployable distress beacon ; when triggered, it will broadcast a signal containing it's name, alongside it's X, Y and Z coordinates in order to let other players locate and retrieve the player who triggered the beacon.
Each beacon can be configured in-game to use the GPS channel of a specific constellation, in order to allow setting up a different, use-specific constellation different from whatever constellation you're otherwise using. 
It also has a name that's proper to it, used to differentiate two beacons when necessary.
In the code, two variables can be tweaked to change the inner workings of the beacon :

`TIMEOUT` is the delay in milliseconds before which a beacon is considered unresponsive by your own.

`REFRESH_RATE` is the rate at which the beacon refreshes itself.

Configuration for the beacon's settings is stored in `beacon.cfg` on the computer's filesystem, and can be reset by pressing the "Terminate program" button (or holding Ctrl+T)

##### **Encrypted Chat**

`encrypted-chat.lua` is a peer-to-peer chat that uses the rednet API to allow users to use a chatroom-esque setup along a given rednet channel, with the data being protected by a XOR cipher<sup>1</sup>
The available features are :
1. Automatic name generation
    - The app assigns a randomly generated name to each user upon connection.
2. Manual name choosing
    - Aforementionned name can be changed by the user as often as they would like (which may cause head injuries if you use that to annoy others, I can't really fix that bug).
3. Using different protocols (AKA chatrooms in this context)
    - Messages are broadcast along a specific rednet channel, and received on the same channel.
4. Changing encryption keys on-the-fly
    - Messages are encrypted using a XOR cipher, and users can change their key to be whatever they wish.

## Glossary
1. I chose a XOR cipher for the chat for a (rather bothersome) precise reason. CC:Tweaked uses Lua in a simulated environment, where the game already has to do several different operations in parallel, so using a stronger encryption algorithm would risk overloading the server, given that a XOR cipher takes about fifteen lines, and a proper AES-256 about tenfold.
And we're playing among friends on a Minecraft server, I doubt anyone would go through with breaking such encrypted messages anyways to be honest...