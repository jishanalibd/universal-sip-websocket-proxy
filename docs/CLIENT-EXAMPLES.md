# Client Configuration Examples

This document provides examples of how to configure various SIP clients to use the Universal SIP WebSocket Proxy.

## Table of Contents

1. [JsSIP](#jssip)
2. [SIP.js](#sipjs)
3. [Browser-Phone](#browser-phone)
4. [Linphone](#linphone)
5. [Zoiper](#zoiper)
6. [Testing with wscat](#testing-with-wscat)

## JsSIP

[JsSIP](https://jssip.net/) is a JavaScript SIP library for WebRTC applications.

### Basic Configuration

```javascript
// Create WebSocket connection
var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');

// Configuration
var configuration = {
  sockets: [socket],
  uri: 'sip:user123@sip.mycompany.com',
  password: 'secret',
  display_name: 'John Doe',
  session_timers: false,
  register: true,
  register_expires: 600
};

// Create User Agent
var userAgent = new JsSIP.UA(configuration);

// Event handlers
userAgent.on('connected', function(e) {
  console.log('WebSocket connected');
});

userAgent.on('disconnected', function(e) {
  console.log('WebSocket disconnected');
});

userAgent.on('registered', function(e) {
  console.log('Successfully registered');
});

userAgent.on('registrationFailed', function(e) {
  console.log('Registration failed:', e.cause);
});

userAgent.on('newRTCSession', function(e) {
  var session = e.session;
  
  if (session.direction === 'incoming') {
    console.log('Incoming call from:', session.remote_identity.uri.user);
    
    // Answer call
    session.answer({
      mediaConstraints: {
        audio: true,
        video: false
      }
    });
  }
});

// Start the User Agent
userAgent.start();
```

### Making a Call

```javascript
var eventHandlers = {
  'progress': function(e) {
    console.log('Call in progress');
  },
  'failed': function(e) {
    console.log('Call failed:', e.cause);
  },
  'ended': function(e) {
    console.log('Call ended');
  },
  'confirmed': function(e) {
    console.log('Call confirmed');
  }
};

var options = {
  eventHandlers: eventHandlers,
  mediaConstraints: {
    audio: true,
    video: false
  }
};

// Make call to extension 1001
var session = userAgent.call('sip:1001@sip.mycompany.com', options);
```

### Complete HTML Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>JsSIP WebRTC Phone</title>
  <script src="https://cdn.jsdelivr.net/npm/jssip@3.10.0/dist/jssip.min.js"></script>
</head>
<body>
  <h1>WebRTC Phone</h1>
  
  <div id="login">
    <h2>Login</h2>
    <input id="domain" placeholder="SIP Domain" value="sip.mycompany.com">
    <input id="username" placeholder="Username">
    <input id="password" type="password" placeholder="Password">
    <button onclick="register()">Register</button>
  </div>
  
  <div id="phone" style="display:none">
    <h2>Phone</h2>
    <p>Status: <span id="status">Disconnected</span></p>
    <input id="destination" placeholder="Extension to call">
    <button onclick="makeCall()">Call</button>
    <button onclick="hangup()">Hangup</button>
    <audio id="remoteAudio" autoplay></audio>
  </div>

  <script>
    var userAgent;
    var currentSession;

    function register() {
      var domain = document.getElementById('domain').value;
      var username = document.getElementById('username').value;
      var password = document.getElementById('password').value;

      var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');
      
      var configuration = {
        sockets: [socket],
        uri: 'sip:' + username + '@' + domain,
        password: password,
        register: true
      };

      userAgent = new JsSIP.UA(configuration);

      userAgent.on('registered', function() {
        document.getElementById('status').textContent = 'Registered';
        document.getElementById('login').style.display = 'none';
        document.getElementById('phone').style.display = 'block';
      });

      userAgent.on('newRTCSession', function(e) {
        currentSession = e.session;
        
        currentSession.on('peerconnection', function(e) {
          var peerconnection = e.peerconnection;
          peerconnection.onaddstream = function(e) {
            document.getElementById('remoteAudio').srcObject = e.stream;
          };
        });

        currentSession.on('ended', function() {
          document.getElementById('status').textContent = 'Registered';
        });

        currentSession.on('failed', function() {
          document.getElementById('status').textContent = 'Registered';
        });
      });

      userAgent.start();
    }

    function makeCall() {
      var destination = document.getElementById('destination').value;
      var domain = document.getElementById('domain').value;
      
      var options = {
        mediaConstraints: { audio: true, video: false }
      };

      currentSession = userAgent.call('sip:' + destination + '@' + domain, options);
      document.getElementById('status').textContent = 'Calling...';
    }

    function hangup() {
      if (currentSession) {
        currentSession.terminate();
      }
    }
  </script>
</body>
</html>
```

## SIP.js

[SIP.js](https://sipjs.com/) is another popular JavaScript SIP library.

### Basic Configuration

```javascript
// SIP.js v0.20+
import { Web, UserAgent } from 'sip.js';

const server = 'wss://sipproxy.yourdomain.com:443';
const aor = 'sip:user123@sip.mycompany.com';

const userAgentOptions = {
  authorizationUsername: 'user123',
  authorizationPassword: 'secret',
  transportOptions: {
    server: server
  },
  uri: UserAgent.makeURI(aor)
};

const userAgent = new UserAgent(userAgentOptions);

userAgent.start().then(() => {
  console.log('User agent started');
  
  // Register
  const registerer = new Registerer(userAgent);
  registerer.register();
});
```

### Making a Call

```javascript
import { Inviter } from 'sip.js';

const target = UserAgent.makeURI('sip:1001@sip.mycompany.com');
const inviter = new Inviter(userAgent, target);

inviter.invite().then(() => {
  console.log('Call initiated');
}).catch((error) => {
  console.error('Call failed:', error);
});
```

## Browser-Phone

[Browser-Phone](https://github.com/InnovateAsterisk/Browser-Phone/) is a complete WebRTC phone UI.

### Configuration

Edit the configuration in Browser-Phone's settings:

```javascript
// In globalSettings.js or via UI
var config = {
  // WebSocket Server
  wssServer: 'sipproxy.yourdomain.com',
  WebSocketPort: 443,
  ServerPath: '/',
  
  // SIP Settings
  SipDomain: 'sip.mycompany.com',  // User's actual SIP domain
  SipUsername: 'user123',
  SipPassword: 'secret',
  
  // Display Name
  DisplayName: 'John Doe',
  
  // Features
  EnableVideoCalling: true,
  AutoAnswerEnabled: false,
  DoNotDisturbEnabled: false,
  
  // Audio Settings
  AudioOutputDevice: 'default',
  AudioInputDevice: 'default'
};
```

### Hosting Browser-Phone

1. Clone Browser-Phone:
```bash
git clone https://github.com/InnovateAsterisk/Browser-Phone.git
cd Browser-Phone
```

2. Update config.js with your proxy details

3. Serve via web server:
```bash
# Using Python
python3 -m http.server 8000

# Using Node.js
npx http-server -p 8000

# Using Nginx (production)
# Copy to /var/www/html/phone/
```

4. Access at `http://yourserver:8000`

## Linphone

Linphone desktop and mobile apps support WebSocket connections.

### Desktop Configuration

1. Open Linphone
2. Go to **Preferences** → **Network**
3. Set **Transport**: WSS (WebSocket Secure)
4. Set **SIP Server**: `sipproxy.yourdomain.com:443`
5. Go to **Preferences** → **Accounts**
6. Add Account:
   - **Username**: user123
   - **SIP Domain**: sip.mycompany.com
   - **Password**: secret
   - **Transport**: WSS

### Mobile Configuration

Android/iOS:
1. Use the assistant to add account
2. Select **Use SIP account**
3. Enter:
   - Username: user123
   - Password: secret
   - Domain: sip.mycompany.com
4. Advanced → Transport: WSS
5. Advanced → Proxy: sipproxy.yourdomain.com:443

## Zoiper

### Desktop Configuration

1. Open Zoiper
2. Add Account → Manual Configuration
3. Account Type: SIP
4. Settings:
   - **Domain**: sip.mycompany.com
   - **Username**: user123
   - **Password**: secret
5. Advanced:
   - **Outbound Proxy**: sipproxy.yourdomain.com:443
   - **Transport**: WSS (WebSocket Secure)
   - Check "Use Outbound Proxy"

## Testing with wscat

For basic WebSocket testing:

### Install wscat

```bash
npm install -g wscat
```

### Test Connection

```bash
wscat -c wss://sipproxy.yourdomain.com:443
```

You should see:
```
Connected (press CTRL+C to quit)
>
```

### Send SIP REGISTER

```
REGISTER sip:sip.mycompany.com SIP/2.0
Via: SIP/2.0/WSS df7jal23ls0d.invalid;branch=z9hG4bKnashds7
Max-Forwards: 70
From: <sip:user123@sip.mycompany.com>;tag=a73kszlfl
To: <sip:user123@sip.mycompany.com>
Call-ID: 1j9FpLxk3uxtm8tn@mypc.local
CSeq: 1 REGISTER
Contact: <sip:user123@df7jal23ls0d.invalid;transport=ws>
Expires: 600
Content-Length: 0


```

Note: Press Enter twice after the last line.

## Advanced Configuration

### Multiple Accounts

```javascript
// JsSIP example with multiple accounts
var accounts = [
  {
    uri: 'sip:user1@domain1.com',
    password: 'pass1'
  },
  {
    uri: 'sip:user2@domain2.com',
    password: 'pass2'
  }
];

var userAgents = accounts.map(function(account) {
  var socket = new JsSIP.WebSocketInterface('wss://sipproxy.yourdomain.com:443');
  var config = {
    sockets: [socket],
    uri: account.uri,
    password: account.password
  };
  var ua = new JsSIP.UA(config);
  ua.start();
  return ua;
});
```

### Custom Headers

```javascript
// Add custom SIP headers
var options = {
  extraHeaders: [
    'X-Custom-Header: value',
    'X-Account-Code: 12345'
  ],
  mediaConstraints: {
    audio: true,
    video: false
  }
};

userAgent.call('sip:1001@sip.mycompany.com', options);
```

### STUN/TURN Configuration

```javascript
var configuration = {
  sockets: [socket],
  uri: 'sip:user123@sip.mycompany.com',
  password: 'secret',
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    {
      urls: 'turn:turn.myserver.com:3478',
      username: 'turnuser',
      credential: 'turnpass'
    }
  ]
};
```

## Debugging

### Enable Debug Logging

**JsSIP:**
```javascript
JsSIP.debug.enable('JsSIP:*');
```

**SIP.js:**
```javascript
import { Logger } from 'sip.js';
Logger.setLogLevel('debug');
```

### Browser Console

Open browser developer tools (F12) and check:
- Console for errors
- Network tab for WebSocket connection
- Application tab for storage/cookies

### Common Issues

1. **WebSocket Connection Failed**
   - Check SSL certificate validity
   - Verify domain name
   - Check firewall rules

2. **Registration Failed**
   - Verify SIP credentials
   - Check backend SIP server connectivity
   - Review Kamailio logs

3. **No Audio**
   - Check browser permissions (microphone)
   - Verify rtpengine is running
   - Check NAT/firewall for RTP ports

4. **One-Way Audio**
   - Usually NAT/firewall issue
   - Check rtpengine configuration
   - Verify public IP in rtpengine config

## Resources

- [JsSIP Documentation](https://jssip.net/documentation/)
- [SIP.js Documentation](https://sipjs.com/guides/)
- [Browser-Phone GitHub](https://github.com/InnovateAsterisk/Browser-Phone/)
- [WebRTC Samples](https://webrtc.github.io/samples/)

## Support

For issues with client configuration:
- Check browser compatibility
- Review proxy logs
- Test with simple clients first (wscat)
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
