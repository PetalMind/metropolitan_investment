import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // For now, we'll comment out Firebase initialization to allow the app to run
    // You'll need to set up Firebase project and add the configuration
    /*
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'your-api-key',
        appId: 'your-app-id',
        messagingSenderId: 'your-sender-id',
        projectId: 'cosmopolitan-investment',
        storageBucket: 'cosmopolitan-investment.appspot.com',
      ),
    );
    
    // Enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    */
  }

  // Mock instances for development
  static dynamic get firestore => null; // FirebaseFirestore.instance;
  static dynamic get auth => null; // FirebaseAuth.instance;
} // Firebase Security Rules (to be added in Firebase Console)

const String firestoreRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access data if authenticated
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Clients collection
    match /clients/{clientId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        resource == null &&
        request.resource.data.keys().hasAll(['name', 'email', 'phone', 'createdAt', 'updatedAt']);
      allow update: if request.auth != null && 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['name', 'email', 'phone', 'address', 'updatedAt', 'isActive', 'additionalInfo']);
    }
    
    // Products collection
    match /products/{productId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        resource == null &&
        request.resource.data.keys().hasAll(['name', 'type', 'companyId', 'createdAt', 'updatedAt']);
    }
    
    // Investments collection
    match /investments/{investmentId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        resource == null &&
        request.resource.data.keys().hasAll(['clientId', 'productType', 'productName', 'investmentAmount', 'signedDate', 'createdAt', 'updatedAt']);
    }
    
    // Companies collection
    match /companies/{companyId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        resource == null &&
        request.resource.data.keys().hasAll(['name', 'fullName', 'createdAt', 'updatedAt']);
    }
    
    // Employees collection
    match /employees/{employeeId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        resource == null &&
        request.resource.data.keys().hasAll(['firstName', 'lastName', 'email', 'branchCode', 'createdAt', 'updatedAt']);
    }
  }
}
''';

// Cloud Functions for server-side logic
const String cloudFunctions = '''
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Function to update investment calculations
exports.updateInvestmentCalculations = functions.firestore
    .document('investments/{investmentId}')
    .onWrite(async (change, context) => {
        const investment = change.after.data();
        if (!investment) return;
        
        // Calculate derived fields
        const totalRealized = (investment.realizedCapital || 0) + (investment.realizedInterest || 0);
        const totalRemaining = (investment.remainingCapital || 0) + (investment.remainingInterest || 0);
        const totalValue = totalRealized + totalRemaining;
        const profitLoss = totalValue - (investment.investmentAmount || 0);
        const profitLossPercentage = investment.investmentAmount > 0 ? 
            (profitLoss / investment.investmentAmount) * 100 : 0;
        
        // Update the document with calculated fields
        return change.after.ref.update({
            totalRealized,
            totalRemaining,
            totalValue,
            profitLoss,
            profitLossPercentage,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });

// Function to generate analytics data
exports.generateAnalytics = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        const db = admin.firestore();
        
        // Get all investments
        const investmentsSnapshot = await db.collection('investments').get();
        const investments = investmentsSnapshot.docs.map(doc => doc.data());
        
        // Calculate analytics
        const analytics = {
            totalInvestments: investments.length,
            totalAmount: investments.reduce((sum, inv) => sum + (inv.investmentAmount || 0), 0),
            totalRealized: investments.reduce((sum, inv) => sum + (inv.totalRealized || 0), 0),
            averageReturn: 0, // Calculate based on your logic
            byProductType: {},
            byStatus: {},
            generatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        
        // Save analytics
        return db.collection('analytics').doc('daily').set(analytics);
    });

// Function to send notifications for investments near maturity
exports.checkMaturityNotifications = functions.pubsub
    .schedule('every day 09:00')
    .timeZone('Europe/Warsaw')
    .onRun(async (context) => {
        const db = admin.firestore();
        const thirtyDaysFromNow = new Date();
        thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
        
        const investmentsSnapshot = await db.collection('investments')
            .where('status', '==', 'active')
            .where('redemptionDate', '<=', thirtyDaysFromNow)
            .get();
        
        // Process notifications (implement your notification logic)
        const notifications = [];
        investmentsSnapshot.docs.forEach(doc => {
            const investment = doc.data();
            notifications.push({
                type: 'maturity_warning',
                investmentId: doc.id,
                clientName: investment.clientName,
                productName: investment.productName,
                redemptionDate: investment.redemptionDate,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        
        // Save notifications
        const batch = db.batch();
        notifications.forEach(notification => {
            const ref = db.collection('notifications').doc();
            batch.set(ref, notification);
        });
        
        return batch.commit();
    });
''';
