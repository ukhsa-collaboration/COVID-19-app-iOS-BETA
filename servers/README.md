This is a proxy server that allows for testing the scneario where the
registration confirmation request happens in the background and takes longer
than the 30 seconds that iOS allows.

To use it, first apply the following patch, replacing YOUR_IP with the local
network IP address of your computer.

```
diff --git a/CoLocate/Info.plist b/CoLocate/Info.plist
index c6de0a8..44cca88 100755
--- a/CoLocate/Info.plist
+++ b/CoLocate/Info.plist
@@ -24,6 +24,17 @@
  <string></string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
+ <key>NSAppTransportSecurity</key>
+ <dict>
+   <key>NSExceptionDomains</key>
+   <dict>
+     <key>YOUR_IP</key>
+     <dict>
+       <key>NSThirdPartyExceptionAllowsInsecureHTTPLoads</key>
+       <true/>
+     </dict>
+   </dict>
+ </dict>
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>Bluetooth is used to determine proximity with other citizens, allowing us to detect those who have been close together</string>
  <key>NSBluetoothPeripheralUsageDescription</key>
```

Then replace the hostname in `CoLocate.xcconfig` with the local network IP
address of your computer. Set the `UPSTREAM_SONAR_URL` envrionment variable to
the actual Sonar server URL, and run `node slow-confirmation.js`.  Finally, run
the iOS app.
