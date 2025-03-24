import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_hbb/common.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/models/user_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/common/hbbs/hbbs.dart';
import 'package:flutter_hbb/models/deploy_model.dart';

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
  final RxBool _isDeployCodeMode = false.obs;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RxString _emailError = RxString('');
  final RxString _passwordError = RxString('');
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _emailController.text = UserModel.getLocalUserInfo()?['email'] ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    await gFFI.deployModel.deployWithCode(code);
    if (gFFI.deployModel.error.isEmpty) {
      gFFI.deployModel.checkDeploy();
    }
  }

  Future<void> _deployWithAccount() async {
    if (_emailController.text.isEmpty) {
      _emailError.value = translate('Email missed');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _passwordError.value = translate('Password missed');
      return;
    }

    _isLoading.value = true;
    try {
      final resp = await gFFI.userModel.login(LoginRequest(
        email: _emailController.text,
        password: _passwordController.text,
        id: await bind.mainGetMyId(),
        uuid: await bind.mainGetUuid(),
        autoLogin: true,
        type: HttpType.kAuthReqTypeAccount,
      ));

      if (resp.type == HttpType.kAuthResTypeToken &&
          resp.access_token != null) {
        await bind.mainSetLocalOption(
            key: 'access_token', value: resp.access_token!);
        await bind.mainSetLocalOption(
            key: 'user_info', value: jsonEncode(resp.user ?? {}));
        await UserModel.updateOtherModels();
        await gFFI.deployModel.checkDeploy();
      } else {
        _passwordError.value = translate('Login failed');
      }
    } on RequestException catch (err) {
      _passwordError.value = translate(err.cause);
    } catch (err) {
      _passwordError.value = "Unknown Error: $err";
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHost(context);
  }

  Widget _buildHost(BuildContext context) {
    final model = gFFI.deployModel;
    return Obx(() {
      final bool isLoading =
          model.checking.value || model.deploying.value || _isLoading.value;

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
                  _buildLoadingState(model)
                else
                  _buildHeader(context),
                const SizedBox(height: 24),
                if (_isDeployCodeMode.value)
                  _buildDeployCodeMode(context, isLoading)
                else
                  _buildAccountMode(context, isLoading),
                const SizedBox(height: 16),
                _buildModeSwitchButton(context),
                if (gFFI.deployModel.error.isNotEmpty) _buildErrorText(context),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState(DeployModel model) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          model.checking.value
              ? translate('Checking deployment...')
              : model.deploying.value
                  ? translate('Deploying...')
                  : translate('Logging in...'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          _isDeployCodeMode.value
              ? translate('Enter Deploy Code')
              : translate('Account Deployment'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isDeployCodeMode.value
              ? translate(
                  'Please enter your 12-character deploy code to continue')
              : translate('Please login with your account to continue'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDeployCodeMode(BuildContext context, bool isLoading) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: translate('Deploy Code'),
            hintText: translate('Enter 12-character code'),
            errorText: _errorTextEdit.isEmpty ? null : _errorTextEdit.value,
          ),
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
      ],
    );
  }

  Widget _buildAccountMode(BuildContext context, bool isLoading) {
    return LoginWidgetUserPass(
      email: _emailController,
      pass: _passwordController,
      emailMsg: _emailError.value.isEmpty ? null : _emailError.value,
      passMsg: _passwordError.value.isEmpty ? null : _passwordError.value,
      isInProgress: isLoading,
      curOP: RxString(''),
      onLogin: _deployWithAccount,
      userFocusNode: FocusNode(),
    );
  }

  Widget _buildModeSwitchButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        _isDeployCodeMode.value = !_isDeployCodeMode.value;
        _controller.clear();
        _errorTextEdit.value = '';
        _emailError.value = '';
        _passwordError.value = '';
      },
      child: Text(
        _isDeployCodeMode.value
            ? translate('Use account deployment instead')
            : translate('Use deploy code instead'),
        style: TextStyle(
          color: MyTheme.accent,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SelectableText(
        gFFI.deployModel.error.value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
        textAlign: TextAlign.left,
      ).paddingOnly(top: 8, left: 12),
    );
  }
}
