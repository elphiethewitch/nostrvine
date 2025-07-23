#\!/bin/bash
echo "Testing URL validation logic..."
echo "Expected valid URLs for OpenVine:"
echo "- https://api.openvine.co/media/1751085897568-0fd41442"
echo "- https://blossom.primal.net/test.mp4"
echo "- https://nostr.build/test.gif"
echo ""
echo "The _isValidVideoUrl method should now accept all these URLs."
echo "Check the browser console for logs showing 'hasVideo=true' for these URLs."
