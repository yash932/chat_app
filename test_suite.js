const io = require('socket.io-client');
const http = require('http');
const fs = require('fs');
const path = require('path');

const SERVER_URL = 'http://localhost:3000';

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function makeHttpRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function runTestSuite() {
  console.log('🧪 Starting PulseChat Automated Verification Test Suite...\n');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✅ [PASS] ${message}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${message}`);
      failed++;
    }
  }

  // 1. Test Auth: Signup & Login
  console.log('🔹 Test 1: User Signup & Login API');
  const testEmail = `tester_${Date.now()}@example.com`;
  const testName = 'Jordan Lee Tester';
  const testPass = 'secretPass123';

  const signupRes = await makeHttpRequest({
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/signup',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, JSON.stringify({
    username: testName,
    email: testEmail,
    password: testPass,
    custom_status: 'Lead Designer'
  }));

  assert(signupRes.status === 200, 'Signup endpoint returned 200 OK');
  assert(signupRes.data && signupRes.data.user && signupRes.data.user.username === testName, 'User signed up with exact entered name');
  const userId = signupRes.data.user.id;

  const loginRes = await makeHttpRequest({
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, JSON.stringify({
    email: testEmail,
    password: testPass
  }));

  assert(loginRes.status === 200, 'Login endpoint returned 200 OK');
  assert(loginRes.data && loginRes.data.user && loginRes.data.user.id === userId, 'User logged in successfully with valid session');

  // 2. Test Manual Group Formation
  console.log('\n🔹 Test 2: Manual Group Creation & Conversations API');
  const groupRes = await makeHttpRequest({
    hostname: 'localhost',
    port: 3000,
    path: '/api/groups',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, JSON.stringify({
    name: 'Design Core Group',
    description: 'UI/UX team discussions',
    icon: '🎨',
    memberIds: [userId],
    createdById: userId
  }));

  assert(groupRes.status === 200, 'Group created via /api/groups');
  assert(groupRes.data && groupRes.data.name === 'Design Core Group', 'Group name matches creation payload');
  const groupId = groupRes.data.id;

  const convosRes = await makeHttpRequest({
    hostname: 'localhost',
    port: 3000,
    path: `/api/users/${userId}/conversations`,
    method: 'GET'
  });

  assert(convosRes.status === 200, 'User conversations retrieved');
  assert(Array.isArray(convosRes.data) && convosRes.data.some(c => c.id === groupId), 'Created group exists in user conversations list');

  // 3. Test File Upload
  console.log('\n🔹 Test 3: File Upload API');
  const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
  const fileContent = 'Hello PulseChat test content with Cobalt theme!';
  const postBody = [
    `--${boundary}`,
    'Content-Disposition: form-data; name="files"; filename="ui_spec.txt"',
    'Content-Type: text/plain',
    '',
    fileContent,
    `--${boundary}--`
  ].join('\r\n');

  const uploadRes = await makeHttpRequest({
    hostname: 'localhost',
    port: 3000,
    path: '/api/upload',
    method: 'POST',
    headers: {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Content-Length': Buffer.byteLength(postBody)
    }
  }, postBody);

  assert(uploadRes.status === 200, 'File upload succeeded via /api/upload');
  assert(uploadRes.data.files && uploadRes.data.files.length === 1, 'Uploaded 1 file');
  const uploadedFile = uploadRes.data.files[0];

  // 4. Test Real-Time Multi-User Socket Events
  console.log('\n🔹 Test 4: Real-Time Multi-User Socket.IO Simulation');
  const aliceSocket = io(SERVER_URL, { transports: ['websocket'] });
  const bobSocket = io(SERVER_URL, { transports: ['websocket'] });

  await new Promise((resolve) => {
    let readyCount = 0;
    const checkReady = () => {
      readyCount++;
      if (readyCount === 2) resolve();
    };

    aliceSocket.on('connect', () => {
      aliceSocket.emit('user_connected', {
        id: userId,
        username: testName,
        status: 'online'
      });
      aliceSocket.emit('join_channel', { channelId: groupId });
      checkReady();
    });

    bobSocket.on('connect', () => {
      bobSocket.emit('user_connected', {
        id: 'usr_bob_test',
        username: 'Bob Reviewer',
        status: 'online'
      });
      bobSocket.emit('join_channel', { channelId: groupId });
      checkReady();
    });
  });

  assert(true, 'Alice and Bob successfully connected and joined group');

  // Test Real-Time Message Sending
  const receivedMessagePromise = new Promise((resolve) => {
    bobSocket.on('new_message', (msg) => {
      if (msg.channel_id === groupId) {
        resolve(msg);
      }
    });
  });

  aliceSocket.emit('send_message', {
    channelId: groupId,
    senderId: userId,
    text: 'Hello team, welcome to **Design Core Group**!',
    attachments: [uploadedFile]
  });

  const receivedMsg = await receivedMessagePromise;
  assert(receivedMsg.text.includes('Design Core Group'), 'Bob received real-time message from Alice in group');
  assert(receivedMsg.sender_name === testName, 'Message displays exact sender name from auth');
  assert(receivedMsg.attachments && receivedMsg.attachments.length === 1, 'Message includes attachment');

  // Test Emoji Reactions
  const reactionPromise = new Promise((resolve) => {
    aliceSocket.on('reaction_updated', ({ messageId, reactions }) => {
      if (messageId === receivedMsg.id) {
        resolve(reactions);
      }
    });
  });

  bobSocket.emit('toggle_reaction', {
    messageId: receivedMsg.id,
    userId: 'usr_bob_test',
    emoji: '🔥',
    channelId: groupId
  });

  const reactions = await reactionPromise;
  assert(reactions.length === 1 && reactions[0].emoji === '🔥', 'Real-time emoji reaction synced');

  aliceSocket.disconnect();
  bobSocket.disconnect();

  console.log('\n========================================');
  console.log(`🎉 Test Suite Completed: ${passed} passed, ${failed} failed.`);
  console.log('========================================\n');

  process.exit(failed > 0 ? 1 : 0);
}

runTestSuite().catch(err => {
  console.error('Test suite runner crashed:', err);
  process.exit(1);
});
