import 'package:hwkj_api_core/src/models/ajax_result_entity.dart';

ajaxResultEntityFromJson(AjaxResultEntity data, Map<String, dynamic> json) {
  if (json['Type'] != null) {
    data.type = json['Type'] is String
        ? int.tryParse(json['Type'])
        : json['Type'].toInt();
  }
  if (json['Content'] != null) {
    data.content = json['Content'].toString();
  }
  if (json['Data'] != null) {
    data.data = json['Data'];
  }
  return data;
}

Map<String, dynamic> ajaxResultEntityToJson(AjaxResultEntity entity) {
  final Map<String, dynamic> data = {};
  data['Type'] = entity.type;
  data['Content'] = entity.content;
  data['Data'] = entity.data;
  return data;
}
