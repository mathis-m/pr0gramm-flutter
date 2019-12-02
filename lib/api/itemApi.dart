import 'package:pr0gramm/api/dtos/getItemInfoResponse.dart';
import 'package:pr0gramm/api/dtos/getItemsResponse.dart';

import 'baseApi.dart';

class ItemApi extends BaseApi {
  Future<GetItemsResponse> getItems({int flags, bool promoted = false, int older}) async {
    final response = await client.get("/items/get?flags=$flags${promoted ? "&promoted=1" : ""}${older != null ? "&older=$older" : ""}");
    return GetItemsResponse.fromJson(response.data);
  }
  Future<GetItemInfoResponse> getItemInfo(int itemId) async {
    final response = await client.get("/items/info?itemId=$itemId");
    return GetItemInfoResponse.fromJson(response.data);
  }
}