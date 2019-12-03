import 'package:dio/dio.dart';
import 'package:pr0gramm/api/dtos/getItemsResponse.dart';
import 'package:pr0gramm/api/dtos/itemInfoResponse.dart';
import 'package:pr0gramm/data/sharedPrefKeys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'baseApi.dart';

enum Vote {
  DOWN,
  CLEAR,
  UP,
  FAVORITE,
}

class ItemApi extends BaseApi {
  Future<GetItemsResponse> getItems(
      {int flags, bool promoted = false, int older}) async {
    final response = await client.get(
        "/items/get?flags=$flags${promoted ? "&promoted=1" : ""}${older != null ? "&older=$older" : ""}");
    return GetItemsResponse.fromJson(response.data);
  }

  Future<ItemInfoResponse> getItemInfo(int itemId) async {
    final response = await client.get("/items/info?itemId=$itemId");
    return ItemInfoResponse.fromJson(response.data);
  }

  void vote(int itemId, Vote value) async {
    var voteValue = Vote.values.indexOf(value) - 1;
    final prefs = await SharedPreferences.getInstance();
    final nonce = prefs.getString(SharedPrefKeys.NONCE);
    print(nonce);
    await client.post("/items/vote",
        data: FormData.fromMap({
          "id": itemId,
          "vote": voteValue,
          "_nonce": nonce,
        })); //id=$itemId&vote=$value&_nonce=$nonce
  }
}
