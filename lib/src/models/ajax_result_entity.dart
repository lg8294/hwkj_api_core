import 'package:hwkj_api_core/generated/json/base/json_convert_content.dart';
import 'package:hwkj_api_core/generated/json/base/json_field.dart';

class AjaxResultEntity with JsonConvert<AjaxResultEntity> {
  /// [200, 203, 401, 403, 404, 423, 500]
  @JSONField(name: "Type")
  int type;

  @JSONField(name: "Message")
  String content;

  @JSONField(name: "Data")
  dynamic data;
}
