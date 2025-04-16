import 'package:pocketbase/pocketbase.dart';
import '../config/pocketbase_config.dart';
import '../models/user_model.dart';

class UserService {
  final PocketBase pb = PocketBaseConfig.pb;

  Future<List<UserModel>> getAllUsers() async {
    final result = await pb.collection(PocketBaseConfig.usersCollection).getList(perPage: 100);
    return result.items.map((item) => UserModel.fromJson(item.toJson())).toList();
  }
}
