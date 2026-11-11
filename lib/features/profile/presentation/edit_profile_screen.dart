import 'dart:typed_data';

import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/profile/application/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// The member's own profile. Writes only their own document.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  Uint8List? _pickedPhoto;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Fills the fields once, from the session. Doing this in `build` rather
  /// than `initState` keeps it to one place, and the flag stops a rebuild
  /// from overwriting what the member is in the middle of typing.
  void _prefill(Member member) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = member.name;
    _phoneController.text = member.phone ?? '';
    _emailController.text = member.email ?? '';
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // A first pass at the source, so a 12 MP photo is not read into
      // memory at full size; the real resize happens before upload.
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _pickedPhoto = bytes);
  }

  Future<void> _save() async {
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .save(
          name: _nameController.text,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          photoBytes: _pickedPhoto,
        );

    if (!mounted || !saved) return;
    setState(() => _pickedPhoto = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(authControllerProvider).value?.member;
    final saving = ref.watch(profileControllerProvider);
    final failure = saving.error;

    if (member == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _prefill(member);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('EDIT PROFILE')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Insets.margin,
            Insets.lg,
            Insets.margin,
            Insets.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _Avatar(
                  photoUrl: member.photoUrl,
                  picked: _pickedPhoto,
                  onTap: saving.isLoading ? null : _pickPhoto,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              if (failure != null) ...[
                const SizedBox(height: 16),
                Text(
                  failure is RepositoryFailure
                      ? failure.message
                      : 'Could not save. Try again.',
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              DfPrimaryButton(
                label: 'Save changes',
                trailingIcon: Icons.check,
                busy: saving.isLoading,
                onPressed: _save,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.picked, this.onTap});

  final String? photoUrl;
  final Uint8List? picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = picked;
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.surfaceContainerLow,
        backgroundImage: bytes != null
            ? MemoryImage(bytes)
            : (photoUrl != null ? NetworkImage(photoUrl!) : null)
                  as ImageProvider<Object>?,
        child: bytes == null && photoUrl == null
            ? const Icon(Icons.add_a_photo_outlined, size: 28)
            : null,
      ),
    );
  }
}
