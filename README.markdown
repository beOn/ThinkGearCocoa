ThinkGearCocoa
==============

ThinkGearCocoa is a collection of classes that make it easier for Cocoa programmers to work with [NeuroSky's ThinkGear Connector API](http://developer.neurosky.com/docs/doku.php?id=thinkgear_connector_tgc). This code is released under the BSD 3-Clause License. See License.txt for more on that.

Classes
=======

There are two important classes in ThinkGearCocoa: TCReader, and TCEventGraphController. The former makes it easy to consume data from a NeuroSky device, and the latter uses [core-plot](http://code.google.com/p/core-plot/) to make it easy to generate nice graphs based on data from a NeuroSky device.

TCReader
--------

TCReader is a [singleton class](http://cocoawithlove.com/2008/11/singletons-appdelegates-and-top-level.html) whose instance exposes two methods, its connection state, and a delegate property. The methods are pretty self explanatory:

	+ (void)connectToReader;
	+ (void)disconnectFromReader;

Objects who become the TCReader instance's delegate should implement the TCReaderDelegate protocol. This defines two callbacks:

	- (void)TCReaderDidReadEvent:(TCReadEvent)readEvent;
	- (void)TCReaderConnectionStateDidChange:(TCReader*)reader;

The TCReadEvent you get back whenever the TCReader gets new data is a C struct that contains float values for signal quality, blink strength, meditation, attention, delta, theta, etc., and date received as an NSTimeInterval since the reference date. At this point TCReader does not report raw EEG scores. If you want raw EEG scores, add (or comment on) an issue [here](https://github.com/beOn/ThinkGearCocoa/issues), or fork!

On receipt of TCReaderConnectionStateDidChange, you can easily find the connection state by calling:

	TCReaderConnectionState state = reader.connectionState;

TCEventGraphController
----------------------

This controller can be a pretty helpful debugging tool, and might act as a decent starting off point for some prototype graph views of your own. It's not too configurable at this point, but I've gotta stop working on this thing and push it out at some point, so I leave changing the framerate and graph scale to you. Hint: some values range between 0 and 100, and others go into the tens of thousands. If you have trouble with this class, or want to use it but would like something a little easier to handle, let me know.

Take note that to use this class you'll have to download and link to [core-plot](http://code.google.com/p/core-plot/). See "Requirements" for more info.

Requirements
============

TCReader
--------

In order to use TCReader in your project must be running [NeuroSky's ThinkGear Connector](http://developer.neurosky.com/docs/doku.php?id=thinkgear_connector_tgc), and must have a NeuroSky device connected to your computer and powered on. Other than that, TCReader has no requirements. Just copy TCReader.h and TCReader.m into your project, and you're ready to rock.

TCEventGraphController
----------------------

TCEventGraphController makes use of [core-plot](http://code.google.com/p/core-plot/), a pretty great Cocoa graphing framework. In order to use it, you'll have to link core-plot into your project. Fortunately, this could hardly be easier: [just follow their instructions as laid out here](http://code.google.com/p/core-plot/wiki/UsingCorePlotInApplications). As part of their instructions, they'll also have you link to the QuartzCore framework.

ThinkGearCocoaDemo.xcodeproj
----------------------------

This app demonstrates TCEventGraphController, so you'll have to download [core-plot](http://code.google.com/p/core-plot/) and link it into the project. I would gladly provide you with the framework, but it's simply huge, its in mercurial, and I didn't want to make this a huge, mercurial repo.

Room for Improvement
=====================

- The connection method is a little sloppy. I've done some digging around, and can't get the session confirmation... but the readings start coming nonetheless. If someone needs this to be cleaner, either drop me a line or fork it.
- TCEventGraphController could be a little more configurable. This is low hanging fruit for anyone who likes that piece of silverware that makes the most holes at once. Or bug me and I'll do it.

Bugs & Requests
===============

Please report all bugs to [the issues list on github](https://github.com/beOn/ThinkGearCocoa/issues).
