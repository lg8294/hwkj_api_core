// ignore_for_file: non_constant_identifier_names
// ignore_for_file: camel_case_types
// ignore_for_file: prefer_single_quotes

import 'package:hwkj_api_core/generated/json/ajax_result_entity_helper.dart';
import 'package:hwkj_api_core/generated/json/response_result_entity_helper.dart';
// This file is automatically generated. DO NOT EDIT, all your changes would be lost.
import 'package:hwkj_api_core/src/models/ajax_result_entity.dart';
import 'package:hwkj_api_core/src/models/response_result_entity.dart';

mixin class JsonConvert<T> {
  T fromJson(Map<String, dynamic> json) {
    return _getFromJson<T>(runtimeType, this, json);
  }

  Map<String, dynamic> toJson() {
    return _getToJson<T>(runtimeType, this);
  }

  static _getFromJson<T>(Type type, data, json) {
    switch (type) {
      case AjaxResultEntity:
        return ajaxResultEntityFromJson(data as AjaxResultEntity, json) as T;
      case ResponseResultEntity:
        return responseResultEntityFromJson(data as ResponseResultEntity, json)
            as T;
    }
    return data as T;
  }

  static _getToJson<T>(Type type, data) {
    switch (type) {
      case AjaxResultEntity:
        return ajaxResultEntityToJson(data as AjaxResultEntity);
      case ResponseResultEntity:
        return responseResultEntityToJson(data as ResponseResultEntity);
    }
    return data as T;
  }

  //Go back to a single instance by type
  static _fromJsonSingle<M>(json) {
    String type = M.toString();
    if (type == (AjaxResultEntity).toString()) {
      return AjaxResultEntity().fromJson(json);
    }
    if (type == (ResponseResultEntity).toString()) {
      return ResponseResultEntity().fromJson(json);
    }

    return null;
  }

  //list is returned by type
  static M _getListChildType<M>(List data) {
    if (<AjaxResultEntity>[] is M) {
      return data
          .map<AjaxResultEntity>((e) => AjaxResultEntity().fromJson(e))
          .toList() as M;
    }
    if (<ResponseResultEntity>[] is M) {
      return data
          .map<ResponseResultEntity>((e) => ResponseResultEntity().fromJson(e))
          .toList() as M;
    }

    throw Exception("not found");
  }

  static M fromJsonAsT<M>(json) {
    if (json is List) {
      return _getListChildType<M>(json);
    } else {
      return _fromJsonSingle<M>(json) as M;
    }
  }
}
