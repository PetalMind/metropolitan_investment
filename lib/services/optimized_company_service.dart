import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';
import 'base_service.dart';

class OptimizedCompanyService extends BaseService {
  final String _collection = 'companies';

  // Create
  Future<String> createCompany(Company company) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(company.toFirestore());
      clearCache('companies_list');
      clearCache('companies_count');
      return docRef.id;
    } catch (e) {
      logError('createCompany', e);
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
      logError('getCompany', e);
      throw Exception('Failed to get company: $e');
    }
  }

  // Read all z limitami
  Stream<List<Company>> getCompanies({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList(),
    );
  }

  // Paginacja firm
  Future<PaginationResult<Company>> getCompaniesPaginated({
    PaginationParams params = const PaginationParams(),
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy(params.orderBy ?? 'name', descending: params.descending)
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final companies = snapshot.docs
          .map((doc) => Company.fromFirestore(doc))
          .toList();

      return PaginationResult<Company>(
        items: companies,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getCompaniesPaginated', e);
      throw Exception('Failed to get companies with pagination: $e');
    }
  }

  // Search companies z optymalizacją
  Stream<List<Company>> searchCompanies(String query, {int limit = 30}) {
    if (query.isEmpty) return getCompanies(limit: limit);

    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(limit)
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
      clearCache('companies_list');
    } catch (e) {
      logError('updateCompany', e);
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
      clearCache('companies_list');
      clearCache('companies_count');
    } catch (e) {
      logError('deleteCompany', e);
      throw Exception('Failed to delete company: $e');
    }
  }

  // Get companies count z cache
  Future<int> getCompaniesCount() async {
    return getCachedData('companies_count', () async {
      try {
        final snapshot = await firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .count()
            .get();
        return snapshot.count ?? 0;
      } catch (e) {
        logError('getCompaniesCount', e);
        throw Exception('Failed to get companies count: $e');
      }
    });
  }
}
