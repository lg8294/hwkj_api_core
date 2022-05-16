import 'package:hwkj_api_core/src/models/response_result_entity.dart';

responseResultEntityFromJson(
    ResponseResultEntity data, Map<String, dynamic> json) {
  if (json['HResult'] != null) {
    data.result = json['HResult'] is String
        ? int.tryParse(json['HResult'])
        : json['HResult'].toInt();
  }
  if (json['Message'] != null) {
    data.message = json['Message'].toString();
  }
  if (json['DeveloperMessage'] != null) {
    data.developerMessage = json['DeveloperMessage'];
  }
  return data;
}

Map<String, dynamic> responseResultEntityToJson(ResponseResultEntity entity) {
  final Map<String, dynamic> data = new Map<String, dynamic>();
  data['HResult'] = entity.result;
  data['Message'] = entity.message;
  data['DeveloperMessage'] = entity.developerMessage;
  return data;
}
