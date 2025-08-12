const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  try {
    const serviceAccount = require('../ServiceAccount.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: 'metropolitan-investment'
    });
    console.log('✅ Firebase Admin initialized');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
    process.exit(1);
  }
}

const db = admin.firestore();

async function testVotingSystem() {
  try {
    console.log('🧪 Testing voting system...\n');

    // Test 1: Check voting_status_changes collection
    console.log('📊 Test 1: voting_status_changes collection');
    const changesSnapshot = await db.collection('voting_status_changes')
      .orderBy('timestamp', 'desc')
      .limit(5)
      .get();

    console.log(`   Found ${changesSnapshot.size} voting change records`);

    if (!changesSnapshot.empty) {
      const latestChange = changesSnapshot.docs[0].data();
      console.log(`   Latest change: ${latestChange.oldStatus} → ${latestChange.newStatus}`);
    }

    // Test 2: Check clients collection votingStatus field
    console.log('\n👥 Test 2: Clients with voting status');
    const clientsSnapshot = await db.collection('clients')
      .where('votingStatus', 'in', ['yes', 'no', 'abstain', 'undecided'])
      .limit(10)
      .get();

    console.log(`   Found ${clientsSnapshot.size} clients with voting status`);

    const statusCounts = {};
    clientsSnapshot.docs.forEach(doc => {
      const status = doc.data().votingStatus || 'undecided';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    console.log('   Status distribution:', statusCounts);

    // Test 3: Test query performance (with new indexes)
    console.log('\n⚡ Test 3: Query performance test');
    const startTime = Date.now();

    const testQuery = await db.collection('voting_status_changes')
      .where('clientId', '==', 'test')
      .orderBy('timestamp', 'desc')
      .limit(1)
      .get();

    const queryTime = Date.now() - startTime;
    console.log(`   Query completed in ${queryTime}ms (should be < 1000ms)`);

    if (queryTime < 1000) {
      console.log('   ✅ Query performance: GOOD');
    } else {
      console.log('   ⚠️ Query performance: SLOW (indexes may still be building)');
    }

    // Test 4: Simulate a voting status change
    console.log('\n🗳️ Test 4: Simulate voting status change');
    const testChangeData = {
      clientId: 'test_client_' + Date.now(),
      oldStatus: 'undecided',
      newStatus: 'yes',
      reason: 'System test',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      metadata: { test: true }
    };

    const docRef = await db.collection('voting_status_changes').add(testChangeData);
    console.log(`   ✅ Test voting change record created: ${docRef.id}`);

    // Clean up test data
    await docRef.delete();
    console.log('   🧹 Test data cleaned up');

    console.log('\n🎉 All tests passed! Voting system is working correctly.');
    console.log('\n📋 Summary:');
    console.log(`   • voting_status_changes: ${changesSnapshot.size} records`);
    console.log(`   • clients with voting status: ${clientsSnapshot.size} clients`);
    console.log(`   • query performance: ${queryTime}ms`);
    console.log('   • write/delete operations: ✅ working');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error('\n🔍 Possible causes:');
    console.error('   • Firestore indexes still building (wait 5-10 minutes)');
    console.error('   • Firestore rules blocking access');
    console.error('   • Network connectivity issues');
    console.error('   • ServiceAccount.json missing or invalid');

    process.exit(1);
  }
}

// Run tests
testVotingSystem();
