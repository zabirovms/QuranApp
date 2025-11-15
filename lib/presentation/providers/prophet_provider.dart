import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/local/prophet_local_datasource.dart';
import '../../../data/models/prophet_model.dart';

final prophetLocalDataSourceProvider = Provider<ProphetLocalDataSource>((ref) => ProphetLocalDataSource());

final prophetsProvider = FutureProvider<List<ProphetModel>>((ref) async {
  final dataSource = ref.watch(prophetLocalDataSourceProvider);
  return await dataSource.getAllProphets();
});

