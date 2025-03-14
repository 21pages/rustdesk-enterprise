import 'dart:convert';

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import '../../utils/http_service.dart' as http;

class DeployModel {
  final RxBool isDeployed = false.obs;
  final RxBool checking = false.obs;
  final RxBool deploying = false.obs;
  final RxString error = ''.obs;
  final RxString team = ''.obs;
  final RxString group = ''.obs;

  Future<void> checkDeploy() async {
    try {
      checking.value = true;
      error.value = '';
      isDeployed.value = false;
      team.value = '';
      group.value = '';
      final api = "${await bind.mainGetApiServer()}/api/deploy-code/deployed";
      var headers = getHttpHeaders();
      headers['Content-Type'] = "application/json";
      final body = jsonEncode({'id': await bind.mainGetMyId()});
      final resp =
          await http.post(Uri.parse(api), headers: headers, body: body);
      Map<String, dynamic> json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json.containsKey('error')) {
        throw json['error'];
      }
      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }
      if (json['team'] != null) {
        team.value = json['team'];
      }
      if (json['group'] != null) {
        group.value = json['group'];
      }
      isDeployed.value = team.isNotEmpty;
    } catch (e) {
      error.value = e.toString();
    } finally {
      checking.value = false;
    }
  }

  Future<void> deploy(String code) async {
    try {
      deploying.value = true;
      error.value = '';
      final api = "${await bind.mainGetApiServer()}/api/deploy-code/deploy";
      var headers = getHttpHeaders();
      headers['Content-Type'] = "application/json";
      final body = jsonEncode({'id': await bind.mainGetMyId(), 'code': code});
      final resp =
          await http.post(Uri.parse(api), headers: headers, body: body);
      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }
      if (resp.body.isNotEmpty) {
        Map<String, dynamic> json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json.containsKey('error')) {
          throw json['error'];
        }
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      deploying.value = false;
    }
  }
}
