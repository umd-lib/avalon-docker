## Docker for Mac Container Networking

### Automatic Instructions

The following command will retrieve and execute the [installation script](https://github.com/avalonmediasystem/avalon-docker/blob/development/resources/install.sh). It requires `sudo` (root) access, so read through the script first if you want to check what it does.

```
curl https://raw.githubusercontent.com/avalonmediasystem/avalon-docker/development/resources/install.sh | sudo sh
```

### Manual Instructions

Create `/Library/LaunchDaemons/org.avalonmediasystem.lo0.172.16.123.1.plist`:
    
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.avalonmediasystem.lo0.172.16.123.1</string>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
      <string>/sbin/ifconfig</string>
      <string>lo0</string>
      <string>alias</string>
      <string>172.16.123.1</string>
    </array>
    <key>StandardErrorPath</key>
    <string>/var/log/loopback-alias.log</string>
    <key>StandardOutPath</key>
    <string>/var/log/loopback-alias.log</string>
  </dict>
</plist>
```
    
Add to `/etc/hosts`:

```
172.16.123.1    streaming solr matterhorn fedora redis
```

Create `/etc/pf.anchors/rails80`

```
rdr pass inet proto tcp from any to 172.16.123.1 port 80 -> 127.0.0.1 port 3000
```

Create `/Library/LaunchDaemons/org.avalonmediasystem.pf.rails80.plist`:
    
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.avalonmediasystem.pf.rails80</string>
  <key>RunAtLoad</key>
  <true/>
  <key>ProgramArguments</key>
  <array>
    <string>pfctl</string>
    <string>-e</string>
    <string>-f</string>
    <string>/etc/pf.anchors/rails80</string>
  </array>
  <key>StandardErrorPath</key>
  <string>/var/log/pf-rails.log</string>
  <key>StandardOutPath</key>
  <string>/var/log/pf-rails.log</string></dict>
</plist>
```

Execute:

```shell
sudo launchctl load /Library/LaunchDaemons/org.avalonmediasystem.lo0.172.16.123.1.plist
sudo launchctl load /Library/LaunchDaemons/org.avalonmediasystem.pf.rails80.plist
```
