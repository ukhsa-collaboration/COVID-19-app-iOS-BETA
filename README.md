CoLocate
========

This application runs in the background and identifies other people running the
app within the local area by using low energy bluetooth. While the app is running
permanently in the background, it periodically broadcasts and listens for other 
bluetooth-enabled devices (iOS and Android at this time) that also broadcast the
same unique identifier.

How it works
------------
Our unique identifier is also known as our sevice characteristic. In the bluetooth
spec, devices can broadcast the availability of services. Each service can have 
multiple characteristics. We use a characteristic to uniquely identify our service
and distinguish from all other sorts of bluetooth devices.

For every device we find with a matching characteristic, we record an identifier
for the device we saw, the timestamp, and the rssi of the bluetooth signal, which
will allow a team later on to determine who was in close proximity to individuals
infected with the novel coronavirus.

Functionality
-------------
* Passively collect information of who the user has been in proximity with
  (stored locally on the device)
* Allow the user to submit their "contact events" to NHS servers 

Running the app on your own device
----------------------------------
There are no dependencies at this time. To compile the app, download a recent
build of xcode (11.3.1 or newer) and compile the app.

