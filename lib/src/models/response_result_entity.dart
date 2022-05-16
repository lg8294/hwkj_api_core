import 'package:hwkj_api_core/generated/json/base/json_convert_content.dart';
import 'package:hwkj_api_core/generated/json/base/json_field.dart';

class ResponseResultEntity with JsonConvert<ResponseResultEntity> {
  @JSONField(name: "HResult")
  int result;

  @JSONField(name: "Message")
  String message;

  @JSONField(name: "DeveloperMessage")
  dynamic developerMessage;
}
