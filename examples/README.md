# Examples

This directory contains example clients for testing the Universal SIP WebSocket Proxy.

## Test Client

### test-client.html

A simple, standalone HTML file that provides a web-based SIP client for testing your proxy.

**Features:**
- Connect to your WebSocket proxy
- Register with any SIP server
- Make and receive calls
- Real-time logging
- No build or installation required

**Usage:**

1. Open `test-client.html` in a web browser (Chrome, Firefox, Safari, or Edge)
2. Enter your configuration:
   - **WebSocket Proxy URL**: Your proxy address (e.g., `wss://sipproxy.yourdomain.com:443`)
   - **SIP Domain**: Your actual SIP server domain (e.g., `sip.mycompany.com`)
   - **Username**: Your SIP username
   - **Password**: Your SIP password
   - **Display Name**: Optional display name
3. Click "Connect & Register"
4. Once registered, enter a destination number and click "Call"

**Serving the file:**

You can serve this file in several ways:

**Option 1: Open directly in browser**
```bash
# Just open the file
firefox examples/test-client.html
# or
google-chrome examples/test-client.html
```

**Option 2: Use Python's built-in HTTP server**
```bash
cd examples
python3 -m http.server 8000
# Then open http://localhost:8000/test-client.html
```

**Option 3: Use Node.js http-server**
```bash
npm install -g http-server
cd examples
http-server -p 8000
# Then open http://localhost:8000/test-client.html
```

**Option 4: Use Nginx (production)**
```bash
sudo cp examples/test-client.html /var/www/html/sip-test.html
# Then open https://yourdomain.com/sip-test.html
```

**Browser Requirements:**
- Modern browser with WebRTC support (Chrome, Firefox, Safari, Edge)
- HTTPS required for microphone access (except localhost)
- Allow microphone permissions when prompted

**Troubleshooting:**

If you encounter issues:

1. **Check browser console (F12)** for error messages
2. **Verify proxy URL** is correct and accessible
3. **Check SSL certificate** is valid (for WSS connections)
4. **Test WebSocket connection** using wscat:
   ```bash
   wscat -c wss://sipproxy.yourdomain.com:443
   ```
5. **Review proxy logs** for connection attempts
6. **Check firewall** allows WebSocket connections

**Security Note:**

This is a test client for development and debugging. For production:
- Don't expose credentials in the HTML
- Implement server-side authentication
- Use environment variables or configuration files
- Consider using a proper WebRTC client framework
- Implement proper error handling and validation

## Adding More Examples

To add additional examples:

1. Create a new HTML/JS file in this directory
2. Document its usage in this README
3. Test thoroughly with the proxy
4. Submit a pull request

## Resources

- [JsSIP Documentation](https://jssip.net/documentation/)
- [WebRTC Samples](https://webrtc.github.io/samples/)
- [MDN WebRTC API](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API)
