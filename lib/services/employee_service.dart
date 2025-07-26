import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'employees';

  // Create
  Future<String> createEmployee(Employee employee) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(employee.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create employee: $e');
    }
  }

  // Read
  Future<Employee?> getEmployee(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Employee.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get employee: $e');
    }
  }

  // Read all
  Stream<List<Employee>> getEmployees() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('lastName')
        .orderBy('firstName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
        );
  }

  // Get employees by branch
  Stream<List<Employee>> getEmployeesByBranch(String branchCode) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('branchCode', isEqualTo: branchCode)
        .orderBy('lastName')
        .orderBy('firstName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
        );
  }

  // Search employees
  Stream<List<Employee>> searchEmployees(String query) {
    if (query.isEmpty) return getEmployees();

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('lastName')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList(),
        );
  }

  // Update
  Future<void> updateEmployee(String id, Employee employee) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(employee.toFirestore());
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  // Delete (soft delete)
  Future<void> deleteEmployee(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }

  // Get employees count
  Future<int> getEmployeesCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get employees count: $e');
    }
  }

  // Get unique branches
  Future<List<String>> getUniqueBranches() async {
    try {
      final snapshot = await _firestore
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
      throw Exception('Failed to get unique branches: $e');
    }
  }
}
