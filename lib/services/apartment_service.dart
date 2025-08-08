import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/apartment.dart';
import 'base_service.dart';

class ApartmentService extends BaseService {
  static const String collectionName = 'apartments';

  Future<List<Apartment>> getAllApartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching apartments: $e');
      throw Exception('Failed to fetch apartments: $e');
    }
  }

  Future<Apartment?> getApartmentById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return Apartment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching apartment by ID: $e');
      throw Exception('Failed to fetch apartment: $e');
    }
  }

  Future<List<Apartment>> getApartmentsByStatus(ApartmentStatus status) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('status', isEqualTo: status.displayName)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching apartments by status: $e');
      throw Exception('Failed to fetch apartments by status: $e');
    }
  }

  Future<List<Apartment>> getApartmentsByProject(String projectName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('nazwa_projektu', isEqualTo: projectName)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching apartments by project: $e');
      throw Exception('Failed to fetch apartments by project: $e');
    }
  }

  Future<List<Apartment>> getApartmentsByDeveloper(String developer) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('deweloper', isEqualTo: developer)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching apartments by developer: $e');
      throw Exception('Failed to fetch apartments by developer: $e');
    }
  }

  Future<List<Apartment>> getApartmentsWithRemainingCapital() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('kapital_do_restrukturyzacji', isGreaterThan: 0)
          .orderBy('kapital_do_restrukturyzacji', descending: true)
          .get();

      return snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error fetching apartments with remaining capital: $e');
      throw Exception('Failed to fetch apartments with remaining capital: $e');
    }
  }

  Future<Map<String, dynamic>> getApartmentStatistics() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalApartments': 0,
          'totalValue': 0.0,
          'totalRemainingCapital': 0.0,
          'averageArea': 0.0,
          'statusDistribution': <String, int>{},
          'typeDistribution': <String, int>{},
        };
      }

      final apartments = snapshot.docs
          .map((doc) => Apartment.fromFirestore(doc))
          .toList();

      double totalValue = 0.0;
      double totalRemainingCapital = 0.0;
      double totalArea = 0.0;
      Map<String, int> statusDistribution = {};
      Map<String, int> typeDistribution = {};

      for (final apartment in apartments) {
        totalValue += apartment.totalValue;
        totalRemainingCapital += apartment.remainingValue;
        totalArea += apartment.area;

        // Count status distribution
        final status = apartment.status.displayName;
        statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;

        // Count type distribution
        final type = apartment.apartmentType.displayName;
        typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
      }

      return {
        'totalApartments': apartments.length,
        'totalValue': totalValue,
        'totalRemainingCapital': totalRemainingCapital,
        'averageArea': apartments.isNotEmpty
            ? totalArea / apartments.length
            : 0.0,
        'statusDistribution': statusDistribution,
        'typeDistribution': typeDistribution,
      };
    } catch (e) {
      print('❌ Error calculating apartment statistics: $e');
      throw Exception('Failed to calculate apartment statistics: $e');
    }
  }

  Future<void> createApartment(Apartment apartment) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(apartment.id)
          .set(apartment.toFirestore());
    } catch (e) {
      print('❌ Error creating apartment: $e');
      throw Exception('Failed to create apartment: $e');
    }
  }

  Future<void> updateApartment(Apartment apartment) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(apartment.id)
          .update(apartment.toFirestore());
    } catch (e) {
      print('❌ Error updating apartment: $e');
      throw Exception('Failed to update apartment: $e');
    }
  }

  Future<void> deleteApartment(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(id)
          .delete();
    } catch (e) {
      print('❌ Error deleting apartment: $e');
      throw Exception('Failed to delete apartment: $e');
    }
  }

  // Batch operations for data import
  Future<void> createApartmentsBatch(List<Apartment> apartments) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final apartment in apartments) {
        final docRef = firestore.collection(collectionName).doc(apartment.id);
        batch.set(docRef, apartment.toFirestore());
      }

      await batch.commit();
      print('✅ Successfully created ${apartments.length} apartments in batch');
    } catch (e) {
      print('❌ Error creating apartments batch: $e');
      throw Exception('Failed to create apartments batch: $e');
    }
  }
}
