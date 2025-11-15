import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/local/asmaul_husna_local_datasource.dart';
import '../../../data/models/asmaul_husna_model.dart';

final asmaulHusnaLocalDataSourceProvider = Provider<AsmaulHusnaLocalDataSource>((ref) => AsmaulHusnaLocalDataSource());

final asmaulHusnaProvider = FutureProvider<List<AsmaulHusnaModel>>((ref) async {
  final dataSource = ref.watch(asmaulHusnaLocalDataSourceProvider);
  return await dataSource.getAllNames();
});

