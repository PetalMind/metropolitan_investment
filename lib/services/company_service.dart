import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'companies';

  // Create
  Future<String> createCompany(Company company) async {
    try {
      final docRef = await _firestore
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
      final doc = await _firestore.collection(_collection).doc(id).get();
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
    return _firestore
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

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateCompany(String id, Company company) async {
    try {
      await _firestore
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
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  // Get companies count
  Future<int> getCompaniesCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get companies count: $e');
    }
  }
}
