# BeatFever Mania

![Beatfever logo](http://i.imgur.com/5zG4Sum.png)

![love2D version](https://img.shields.io/badge/Love2D-0.10.1-EA316E.svg)


![Beatfever SplashScreen](http://i.imgur.com/8bgqDiQ.gif)

>**Current state:** _Active development!_

#FAQ ~ Frequently Asked Questions
####What's this?
_Beatfever Mania_ is an open-source reimplementation of the **osu!** "game engine" in love2D, meaning you play it in a similar style.
Currently the one and probably only implemented gamemode is "Catch the Beat", which works similarly to the original version.
Also, this project strives to keep it's code as simple and clean as possible.

####Where does it run? What are the requirements?
Currently, _BeatFever_ runs with _minor_ modifications in Android, iOS(untested), RaspberryPi (B+ or newer) and with no modifications at all on Windows, MacOS and Linux.
On desktop systems, anything that supports OpenGLES 2.1 or OpenGL 2 and has anything that _vaguely resembles a processor_ should run this with no issues.

####What's done and what's coming up next?
The game in itself works already, but hasn't all the mechanics implemented yet. Song installation and selection works, but still needs updates. There is also no end game stat screen yet. We're aiming at an eventual storyboard support aswell.

####How do i run this?
The github version of the game will most likely crash on startup complaining about a "song.mp3". This is because a song is currently hardcoded to be loaded at game startup on a folder called "Songs".
I'll be fixing that very soon, since i'm making an official theme song for this, but in the meantime, creating a folder called "Songs" and putting any "song.mp3" music file in it will make it work.

####How do i install new songs?
Just drag and drop any .osz files in the Selection Screen. After a tad bit it should pop up on the list.

-------
Any questions, rants or requests, [drop me an email here](mailto:pedrorocha@gec.inatel.br)
