import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/serbia_locations.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/city_neighborhood_fields.dart';
import '../../../core/widgets/feed_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/storage_service.dart';
import '../../legal/presentation/legal_consent_text.dart';
import '../domain/auth_exception.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';
import 'forgot_password_dialog.dart';
import 'widgets/auth_text_field.dart';
// Phase: Google Sign-In hidden — re-enable with google_sign_in_button.dart
// import 'widgets/google_sign_in_button.dart';

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
  final _customNeighborhoodController = TextEditingController();
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
    _customNeighborhoodController.dispose();
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

  Future<void> _forgotPassword() async {
    await showForgotPasswordDialog(
      context,
      initialEmail: _signInEmailController.text.trim(),
    );
  }

  Future<void> _submitSignUp() async {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final city = SerbiaLocations.cityById(_cityId);
    final neighborhoodId = _neighborhoodId;
    if (city == null || neighborhoodId == null || neighborhoodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.neighborhoodRequired)),
      );
      return;
    }
    final customName = _customNeighborhoodController.text.trim();
    if (SerbiaLocations.usesCustomNeighborhood(_cityId, neighborhoodId) &&
        customName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.customNeighborhoodRequired)),
      );
      return;
    }
    final neighborhoodName = SerbiaLocations.resolveNeighborhoodName(
      cityId: city.id,
      neighborhoodId: neighborhoodId,
      customName: customName,
    );
    if (neighborhoodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.neighborhoodRequired)),
      );
      return;
    }
    final storedHoodId = SerbiaLocations.usesCustomNeighborhood(
          city.id,
          neighborhoodId,
        )
        ? SerbiaLocations.customNeighborhoodId
        : neighborhoodId;
    final ownerPhoto =
        _ownerPhotoUrl.startsWith('http') ? _ownerPhotoUrl.trim() : '';
    final success = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _signUpEmailController.text.trim(),
          password: _signUpPasswordController.text,
          city: city.name,
          cityId: city.id,
          neighborhoodId: storedHoodId,
          neighborhoodName: neighborhoodName,
          bio: '',
          customPhotoUrl: ownerPhoto,
        );
    if (!mounted || !success) {
      return;
    }
    // Belt-and-suspenders: ensure photo is persisted even if signup write
    // raced ahead of Auth user creation.
    if (ownerPhoto.isNotEmpty) {
      try {
        final uid = ref.read(authStateProvider).asData?.value?.uid ??
            FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          await ref.read(authRepositoryProvider).saveOwnerCustomPhoto(
                uid: uid,
                customPhotoUrl: ownerPhoto,
              );
        }
      } catch (error) {
        debugPrint('Owner photo save after register: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.photoUploadFailed)),
          );
        }
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
    setState(() => _uploadingOwnerPhoto = true);
    try {
      final storage = StorageService();
      final previous = _ownerPhotoUrl;
      final url = await storage.uploadImageFromGallery(folderName: 'users');
      if (url == null) {
        return;
      }
      if (!url.startsWith('http')) {
        throw StateError(AppStrings.photoUploadFailed);
      }
      if (mounted) {
        setState(() => _ownerPhotoUrl = url);
      }
      await storage.tryDeleteImageByUrl(previous);
    } catch (error) {
      if (mounted) {
        showNetworkErrorSnackBar(
          context,
          error,
          fallback: AppStrings.photoUploadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingOwnerPhoto = false);
      }
    }
  }

  // Phase: Google Sign-In hidden.
  // Future<void> _signInWithGoogle() async {
  //   final success =
  //       await ref.read(authControllerProvider.notifier).signInWithGoogle();
  //   if (!mounted || !success) {
  //     return;
  //   }
  //   Navigator.of(context).popUntil((route) => route.isFirst);
  // }

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
    final isLoading = authAction.isLoading;
    final error = authAction.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp ? AppStrings.signUpTab : AppStrings.logInTitle,
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: AppStrings.logInTitle),
            Tab(text: AppStrings.signUpTab),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _SignInForm(
              formKey: _signInFormKey,
              emailController: _signInEmailController,
              passwordController: _signInPasswordController,
              obscurePassword: _obscureSignInPassword,
              error: error,
              isLoading: isLoading,
              onToggleObscure: () {
                setState(
                  () => _obscureSignInPassword = !_obscureSignInPassword,
                );
              },
              onSubmit: isLoading ? null : _submitSignIn,
              onForgotPassword: isLoading ? null : _forgotPassword,
            ),
            _SignUpForm(
              formKey: _signUpFormKey,
              nameController: _nameController,
              emailController: _signUpEmailController,
              passwordController: _signUpPasswordController,
              confirmController: _confirmController,
              customNeighborhoodController: _customNeighborhoodController,
              cityId: _cityId,
              neighborhoodId: _neighborhoodId,
              ownerPhotoUrl: _ownerPhotoUrl,
              uploadingOwnerPhoto: _uploadingOwnerPhoto,
              obscurePassword: _obscurePassword,
              obscureConfirm: _obscureConfirm,
              error: error,
              isLoading: isLoading,
              onCityChanged: (value) {
                setState(() {
                  _cityId = value;
                  _neighborhoodId = null;
                  _customNeighborhoodController.clear();
                });
              },
              onNeighborhoodChanged: (value) {
                setState(() {
                  _neighborhoodId = value;
                  if (!SerbiaLocations.isCustomNeighborhoodId(value)) {
                    _customNeighborhoodController.clear();
                  }
                });
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
        // Phase: Google Sign-In UI hidden — restore divider + GoogleSignInButton here.
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
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final Object? error;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSubmit;
  final VoidCallback? onForgotPassword;

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
              BrandMark(),
              SizedBox(height: 24),
              AuthTextField(
                controller: emailController,
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
              ),
              SizedBox(height: 16),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : onForgotPassword,
                      child: Text(AppStrings.forgotPassword),
                    ),
                  ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _authErrorMessage(error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              SizedBox(height: 24),
              if (isLoading)
                Center(child: CircularProgressIndicator())
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
    required this.customNeighborhoodController,
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
  final TextEditingController customNeighborhoodController;
  final String cityId;
  final String? neighborhoodId;
  final String ownerPhotoUrl;
  final bool uploadingOwnerPhoto;
  final bool obscurePassword;
  final bool obscureConfirm;
  final Object? error;
  final bool isLoading;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
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
                                      loadingBuilder:
                                          (context, child, progress) {
                                        if (progress == null) {
                                          return child;
                                        }
                                        return const SoftPlaceholder(
                                          width: 72,
                                          height: 72,
                                          borderRadius: 36,
                                        );
                                      },
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
                    SizedBox(height: 8),
                    Text(
                      ownerPhotoUrl.startsWith('http')
                          ? AppStrings.ownerPhotoLabel
                          : AppStrings.addOwnerPhoto,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
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
              SizedBox(height: 16),
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
              CityNeighborhoodFields(
                cityId: cityId,
                neighborhoodId: neighborhoodId,
                customNeighborhoodController: customNeighborhoodController,
                onCityChanged: onCityChanged,
                onNeighborhoodChanged: onNeighborhoodChanged,
                enabled: !isLoading,
              ),
              SizedBox(height: 16),
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
              SizedBox(height: 16),
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
              SizedBox(height: 20),
              const LegalConsentText(),
              SizedBox(height: 16),
              if (isLoading)
                Center(child: CircularProgressIndicator())
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
