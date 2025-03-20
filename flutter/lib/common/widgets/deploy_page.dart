import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_hbb/common.dart';
import 'dart:async';

class DeployPage extends StatefulWidget {
  const DeployPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DeployPage> createState() => _DeployPageState();
}

class _DeployPageState extends State<DeployPage> {
  final TextEditingController _controller = TextEditingController();
  final RxString _errorTextEdit = ''.obs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deployWithCode(String code) async {
    if (code.length != 12) {
      _errorTextEdit.value = translate('Deploy code must be 12 characters');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9]{12}$').hasMatch(code)) {
      _errorTextEdit.value = translate('Invalid deploy code');
      return;
    }
    await gFFI.deployModel.deploy(code);
    if (gFFI.deployModel.error.isEmpty) {
      gFFI.deployModel.checkDeploy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHost(context);
  }

  Widget _buildHost(BuildContext context) {
    final model = gFFI.deployModel;
    return Obx(() {
      final bool isLoading = model.checking.value || model.deploying.value;

      return Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        model.checking.value
                            ? translate('Checking deployment...')
                            : translate('Deploying...'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        translate('Enter Deploy Code'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        translate(
                            'Please enter your 12-character deploy code to continue'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: translate('Deploy Code'),
                      hintText: translate('Enter 12-character code'),
                      errorText:
                          _errorTextEdit.isEmpty ? null : _errorTextEdit.value),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  onChanged: (_) => _errorTextEdit.value = '',
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            _deployWithCode(_controller.text.trim());
                          },
                    child: Text(
                      translate('Deploy'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                if (gFFI.deployModel.error.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      gFFI.deployModel.error.value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.left,
                    ).paddingOnly(top: 8, left: 12),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
