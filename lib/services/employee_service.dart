import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import 'base_service.dart';

class EmployeeService extends BaseService {
  final String _collection = 'employees';

  // Create
  Future<String> createEmployee(Employee employee) async {
    try {
      final docRef = await firestore
          .collection(_collection)
          .add(employee.toFirestore());
      clearCache('employees_list');
      return docRef.id;
    } catch (e) {
      logError('createEmployee', e);
      throw Exception('Failed to create employee: $e');
    }
  }

  // Read
  Future<Employee?> getEmployee(String id) async {
    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Employee.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('getEmployee', e);
      throw Exception('Failed to get employee: $e');
    }
  }

  // Read all z optymalizacją - WYKORZYSTUJE indeks isActive + lastName + firstName
  Stream<List<Employee>> getEmployees({int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('lastName')
        .orderBy('firstName');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
    );
  }

  // Paginowana wersja pracowników
  Future<PaginationResult<Employee>> getEmployeesPaginated({
    PaginationParams params = const PaginationParams(),
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy(params.orderBy ?? 'lastName', descending: params.descending)
          .orderBy('firstName')
          .limit(params.limit);

      if (params.startAfter != null) {
        query = query.startAfterDocument(params.startAfter!);
      }

      final snapshot = await query.get();
      final employees = snapshot.docs
          .map((doc) => Employee.fromFirestore(doc))
          .toList();

      return PaginationResult<Employee>(
        items: employees,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == params.limit,
      );
    } catch (e) {
      logError('getEmployeesPaginated', e);
      throw Exception('Failed to get employees with pagination: $e');
    }
  }

  // Get employees by branch z optymalizacją - WYKORZYSTUJE indeks isActive + branchCode + lastName
  Stream<List<Employee>> getEmployeesByBranch(String branchCode, {int? limit}) {
    Query query = firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('branchCode', isEqualTo: branchCode)
        .orderBy('lastName')
        .orderBy('firstName');

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
    );
  }

  // Search employees z optymalizacją
  Stream<List<Employee>> searchEmployees(String query, {int limit = 30}) {
    if (query.isEmpty) return getEmployees(limit: limit);

    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('lastName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateEmployee(String id, Employee employee) async {
    try {
      await firestore
          .collection(_collection)
          .doc(id)
          .update(employee.toFirestore());
      clearCache('employees_list');
      clearCache('unique_branches');
    } catch (e) {
      logError('updateEmployee', e);
      throw Exception('Failed to update employee: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteEmployee(String id) async {
    try {
      await firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      clearCache('employees_list');
      clearCache('unique_branches');
    } catch (e) {
      logError('deleteEmployee', e);
      throw Exception('Failed to delete employee: $e');
    }
  }

  // Get employees count
  Future<int> getEmployeesCount() async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      logError('getEmployeesCount', e);
      throw Exception('Failed to get employees count: $e');
    }
  }

  // Get unique branches z cache
  Future<List<String>> getUniqueBranches() async {
    return getCachedData('unique_branches', () async {
      try {
        final snapshot = await firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .get();

        final branches = <String>{};
        for (final doc in snapshot.docs) {
          final employee = Employee.fromFirestore(doc);
          branches.add(employee.branchCode);
        }

        return branches.toList()..sort();
      } catch (e) {
        logError('getUniqueBranches', e);
        throw Exception('Failed to get unique branches: $e');
      }
    });
  }
}
