import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';
import 'base_service.dart';

class CompanyService extends BaseService {
  final String _collection = 'companies';

  // Create
  Future<String> createCompany(Company company) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(company.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  // Read
  Future<Company?> getCompany(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Company.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get company: $e');
    }
  }

  // Read all
  Stream<List<Company>> getCompanies() {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList(),
        );
  }

  // Search companies
  Stream<List<Company>> searchCompanies(String query) {
    if (query.isEmpty) return getCompanies();

    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateCompany(String id, Company company) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(company.toFirestore());
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteCompany(String id) async {
    try {
      await firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  // Search by tax ID
  Future<Company?> getCompanyByTaxId(String taxId) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('taxId', isEqualTo: taxId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Company.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get company by tax ID: $e');
    }
  }

  // Hard delete
  Future<void> hardDeleteCompany(String id) async {
    try {
      await firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to hard delete company: $e');
    }
  }

  // Get companies count
  Future<int> getCompaniesCount() async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get companies count: $e');
    }
  }

  // Get companies with pagination
  Future<List<Company>> getCompaniesPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get companies with pagination: $e');
    }
  }

  // Validate tax ID format (Polish NIP)
  bool isValidNIP(String nip) {
    final cleanNip = nip.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNip.length != 10) return false;

    final weights = [6, 5, 7, 2, 3, 4, 5, 6, 7];
    int sum = 0;

    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanNip[i]) * weights[i];
    }

    final checkDigit = sum % 11;
    return checkDigit == int.parse(cleanNip[9]);
  }

  // Get companies statistics
  Future<Map<String, dynamic>> getCompaniesStats() async {
    try {
      final activeSnapshot = await firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final inactiveSnapshot = await firestore
          .collection(_collection)
          .where('isActive', isEqualTo: false)
          .count()
          .get();

      return {
        'active': activeSnapshot.count ?? 0,
        'inactive': inactiveSnapshot.count ?? 0,
        'total': (activeSnapshot.count ?? 0) + (inactiveSnapshot.count ?? 0),
      };
    } catch (e) {
      throw Exception('Failed to get companies stats: $e');
    }
  }
}
