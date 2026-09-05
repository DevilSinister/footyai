import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: AppConfig.apiBaseUrl);
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final normalized = AppConfig.validateAndNormalizeApiBaseUrl(
      _apiController.text,
    );
    if (normalized == null) {
      return;
    }

    setState(() => _isSaving = true);
    await AppConfig.saveApiBaseUrl(normalized);
    if (!mounted) {
      return;
    }
    setState(() {
      _apiController.text = normalized;
      _isSaving = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('API address saved: $normalized')));
  }

  Future<void> _reset() async {
    await AppConfig.resetApiBaseUrl();
    if (!mounted) {
      return;
    }
    setState(() => _apiController.text = AppConfig.apiBaseUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API address reset to the build default.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Connection',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set the FastAPI address for this phone. The change applies to new requests immediately and remains after restarting the app.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _apiController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'API address',
                  hintText: '192.168.1.25 or 192.168.1.25:8000',
                  prefixIcon: Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Port 8000 is added automatically when omitted.',
                ),
                validator: (value) {
                  if (AppConfig.validateAndNormalizeApiBaseUrl(value ?? '') ==
                      null) {
                    return 'Enter an IP/host with an optional port, for example 192.168.1.25:8000.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving…' : 'Save API address'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isSaving ? null : _reset,
              child: const Text('Use build default'),
            ),
            const SizedBox(height: 28),
            const Text(
              'For a physical phone, use the computer’s LAN IP and keep both devices on the same Wi-Fi network. The server must be running on port 8000.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
