import '../../../core/result/result.dart';
import 'customer.dart';

abstract interface class CustomerRepository {
  Stream<List<Customer>> watchAll();

  Stream<Customer?> watchById(int id);

  Future<List<Customer>> fetchAll();

  Future<Result<int>> save(Customer customer);

  Future<Result<void>> delete(int id);
}
