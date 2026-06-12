# Forgot Password Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing non-interactive "Forgot Password?" text on the login screen open a bottom sheet where users can request a Firebase password reset email.

**Architecture:** Add `sendPasswordResetEmail` to `AuthService`, then add a `_ForgotPasswordContent` StatefulWidget at the bottom of `login_screen.dart` (same file so it can reuse the private `_OrbitField` widget). Wrap the existing "Forgot Password?" text with a `GestureDetector` that opens `showGlassSheet<bool>`; a `true` result triggers a floating SnackBar.

**Tech Stack:** Flutter, `firebase_auth`, `flutter_riverpod`, existing `showGlassSheet` from `lib/core/widgets/glass_bottom_sheet.dart`

---

### Task 1: Add `sendPasswordResetEmail` to `AuthService`

**Files:**
- Modify: `lib/services/auth_service.dart`

- [ ] **Step 1: Add the method**

Open `lib/services/auth_service.dart`. The full file currently is:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();
}
```

Add one method after `signOut`:

```dart
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
```

Final file:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/services/auth_service.dart
```

Expected output: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/services/auth_service.dart
git commit -m "feat: add sendPasswordResetEmail to AuthService"
```

---

### Task 2: Add `_ForgotPasswordContent` widget and required imports

**Files:**
- Modify: `lib/screens/auth/login_screen.dart`

`_ForgotPasswordContent` is a self-contained `StatefulWidget` that owns the email field, loading state, and inline error display. It pops `true` on success. It lives at the bottom of `login_screen.dart` so it can reuse the private `_OrbitField` widget already defined there.

- [ ] **Step 1: Add missing imports**

The top of `login_screen.dart` currently has these imports:

```dart
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/providers.dart';
import '../../services/firebase_service.dart';
```

Add two more imports after `firebase_service.dart`:

```dart
import '../../core/widgets/glass_bottom_sheet.dart';
import '../../services/auth_service.dart';
```

- [ ] **Step 2: Append `_ForgotPasswordContent` at the end of the file**

After the closing `}` of the `_DotGrid` class (the last class in the file), append:

```dart
class _ForgotPasswordContent extends StatefulWidget {
  final AuthService authService;
  final String initialEmail;

  const _ForgotPasswordContent({
    required this.authService,
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordContent> createState() => _ForgotPasswordContentState();
}

class _ForgotPasswordContentState extends State<_ForgotPasswordContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _msg(e.code));
    } catch (_) {
      setState(() => _error = 'Failed to send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _msg(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter your email and we'll send you a link to reset your password.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _OrbitField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your email' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFEF4444), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
flutter analyze lib/screens/auth/login_screen.dart
```

Expected output: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/login_screen.dart
git commit -m "feat: add _ForgotPasswordContent widget to login screen"
```

---

### Task 3: Wire up the "Forgot Password?" tap handler

**Files:**
- Modify: `lib/screens/auth/login_screen.dart` (~line 339)

- [ ] **Step 1: Replace the non-interactive text with a tappable version**

Find this block inside `_buildFormContent()` in `_LoginScreenState`:

```dart
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
```

Replace it with:

```dart
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final result = await showGlassSheet<bool>(
                    context: context,
                    title: 'Reset Password',
                    content: _ForgotPasswordContent(
                      authService: ref.read(authServiceProvider),
                      initialEmail: _emailCtrl.text.trim(),
                    ),
                  );
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Password reset email sent. Check your inbox.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/screens/auth/login_screen.dart
```

Expected output: `No issues found!`

- [ ] **Step 3: Run the app and test the flow manually**

```bash
flutter run
```

Walk through each scenario:

| Scenario | Expected result |
|---|---|
| Tap "Forgot Password?" with empty login email field | Sheet opens, email field is empty |
| Tap "Forgot Password?" after typing an email in the login form | Sheet opens, email field is pre-filled with that email |
| Submit with empty email field | Validation error: "Enter your email" shown below the field |
| Submit with a valid email | Sheet dismisses; SnackBar: "Password reset email sent. Check your inbox." |
| Swipe sheet down without submitting | Sheet dismisses, no SnackBar |
| Submit while network is slow | Spinner replaces button text during the async call |

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/login_screen.dart
git commit -m "feat: implement forgot password bottom sheet on login screen"
```
