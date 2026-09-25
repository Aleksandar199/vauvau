import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/serbia_locations.dart';
import '../../../core/images/image_upload_service.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/auth_exception.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _cityId = SerbiaLocations.cities.first.id;
  String? _neighborhoodId;
  String _ownerPhotoUrl = '';
  var _uploadingOwnerPhoto = false;
  bool _obscureSignInPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialMode == AuthMode.signUp ? 1 : 0,
    );
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _nameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isSignUp => _tabs.index == 1;

  Future<void> _submitSignIn() async {
    if (!(_signInFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final success =
        await ref.read(authControllerProvider.notifier).signInWithEmail(
              email: _signInEmailController.text.trim(),
              password: _signInPasswordController.text,
            );
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _submitSignUp() async {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final city = SerbiaLocations.cityById(_cityId);
    final neighborhoodId = _neighborhoodId;
    if (city == null || neighborhoodId == null || neighborhoodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.neighborhoodRequired)),
      );
      return;
    }
    String neighborhoodName = '';
    for (final hood in city.neighborhoods) {
      if (hood.id == neighborhoodId) {
        neighborhoodName = hood.name;
        break;
      }
    }
    if (neighborhoodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.neighborhoodRequired)),
      );
      return;
    }
    final success = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _signUpEmailController.text.trim(),
          password: _signUpPasswordController.text,
          city: city.name,
          cityId: city.id,
          neighborhoodId: neighborhoodId,
          neighborhoodName: neighborhoodName,
          bio: '',
        );
    if (!mounted || !success) {
      return;
    }
    if (_ownerPhotoUrl.startsWith('http')) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await ref.read(authRepositoryProvider).saveOwnerCustomPhoto(
              uid: uid,
              customPhotoUrl: _ownerPhotoUrl,
            );
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickOwnerPhoto() async {
    if (_uploadingOwnerPhoto) {
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _uploadingOwnerPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ImageUploadService.upload(bytes);
      if (!url.startsWith('http')) {
        throw StateError(AppStrings.photoUploadFailed);
      }
      if (mounted) {
        setState(() => _ownerPhotoUrl = url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.photoUploadFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingOwnerPhoto = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted || !success) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || previous?.error == error) {
        return;
      }
      final message =
          error is AuthException ? error.message : AppStrings.authUnknownError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
    final authAction = ref.watch(authControllerProvider);
    final busy = ref.read(authControllerProvider.notifier).busy;
    final isLoading = authAction.isLoading;
    final isGoogleLoading = busy == AuthBusy.google;
    final error = authAction.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp ? AppStrings.signUpTab : AppStrings.logInTitle,
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: AppStrings.logInTitle),
            Tab(text: AppStrings.signUpTab),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SignInForm(
                    formKey: _signInFormKey,
                    emailController: _signInEmailController,
                    passwordController: _signInPasswordController,
                    obscurePassword: _obscureSignInPassword,
                    error: error,
                    isLoading: isLoading && !isGoogleLoading,
                    onToggleObscure: () {
                      setState(
                        () => _obscureSignInPassword = !_obscureSignInPassword,
                      );
                    },
                    onSubmit: isLoading ? null : _submitSignIn,
                  ),
                  _SignUpForm(
                    formKey: _signUpFormKey,
                    nameController: _nameController,
                    emailController: _signUpEmailController,
                    passwordController: _signUpPasswordController,
                    confirmController: _confirmController,
                    cityId: _cityId,
                    neighborhoodId: _neighborhoodId,
                    ownerPhotoUrl: _ownerPhotoUrl,
                    uploadingOwnerPhoto: _uploadingOwnerPhoto,
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    error: error,
                    isLoading: isLoading && !isGoogleLoading,
                    onCityChanged: (value) {
                      setState(() {
                        _cityId = value;
                        _neighborhoodId = null;
                      });
                    },
                    onNeighborhoodChanged: (value) {
                      setState(() => _neighborhoodId = value);
                    },
                    onPickOwnerPhoto: _pickOwnerPhoto,
                    onTogglePassword: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    onToggleConfirm: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                    onSubmit: isLoading ? null : _submitSignUp,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(AppStrings.orDivider),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GoogleSignInButton(
                    loading: isGoogleLoading,
                    onPressed: isLoading ? null : _signInWithGoogle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.error,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final Object? error;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandMark(),
              const SizedBox(height: 24),
              AuthTextField(
                controller: emailController,
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: passwordController,
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
                onToggleObscure: onToggleObscure,
                validator: _passwordValidator,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _authErrorMessage(error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PrimaryButton(
                  label: AppStrings.logInTitle,
                  onPressed: onSubmit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.cityId,
    required this.neighborhoodId,
    required this.ownerPhotoUrl,
    required this.uploadingOwnerPhoto,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.error,
    required this.isLoading,
    required this.onCityChanged,
    required this.onNeighborhoodChanged,
    required this.onPickOwnerPhoto,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String cityId;
  final String? neighborhoodId;
  final String ownerPhotoUrl;
  final bool uploadingOwnerPhoto;
  final bool obscurePassword;
  final bool obscureConfirm;
  final Object? error;
  final bool isLoading;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onNeighborhoodChanged;
  final VoidCallback onPickOwnerPhoto;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandMark(),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: uploadingOwnerPhoto ? null : onPickOwnerPhoto,
                      child: CircleAvatar(
                        radius: 36,
                        child: uploadingOwnerPhoto
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : ownerPhotoUrl.startsWith('http')
                                ? ClipOval(
                                    child: Image.network(
                                      ownerPhotoUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return const Icon(
                                          Icons.person,
                                          size: 36,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ownerPhotoUrl.startsWith('http')
                          ? AppStrings.ownerPhotoLabel
                          : AppStrings.addOwnerPhoto,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: nameController,
                label: AppStrings.nameLabel,
                hint: AppStrings.nameHint,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: emailController,
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: cityId,
                decoration: const InputDecoration(
                  labelText: AppStrings.cityLabel,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final city in SerbiaLocations.cities)
                    DropdownMenuItem(
                      value: city.id,
                      child: Text(city.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onCityChanged(value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: neighborhoodId,
                hint: const Text(AppStrings.neighborhoodLabel),
                decoration: const InputDecoration(
                  labelText: AppStrings.neighborhoodLabel,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final hood
                      in SerbiaLocations.cityById(cityId)?.neighborhoods ??
                          const <Neighborhood>[])
                    DropdownMenuItem(
                      value: hood.id,
                      child: Text(hood.name),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onNeighborhoodChanged(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.neighborhoodRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: passwordController,
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onToggleObscure: onTogglePassword,
                validator: _passwordValidator,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: confirmController,
                label: AppStrings.confirmPasswordLabel,
                obscureText: obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
                onToggleObscure: onToggleConfirm,
                validator: (value) {
                  if (value != passwordController.text) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _authErrorMessage(error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PrimaryButton(
                  label: AppStrings.createAccount,
                  onPressed: onSubmit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _authErrorMessage(Object? error) {
  if (error is AuthException) {
    return error.message;
  }
  return AppStrings.authUnknownError;
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || !email.contains('@')) {
    return AppStrings.emailInvalid;
  }
  return null;
}

String? _passwordValidator(String? value) {
  if (value == null || value.length < 6) {
    return AppStrings.passwordTooShort;
  }
  return null;
}
