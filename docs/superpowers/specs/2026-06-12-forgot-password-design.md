# Forgot Password — Design Spec

**Date:** 2026-06-12  
**Status:** Approved

---

## Overview

Add a working "Forgot Password?" flow to the HomeSync login screen. The existing "Forgot Password?" text is already rendered but non-interactive. This spec covers making it functional using Firebase Auth's password reset email API, surfaced via the app's existing `showGlassSheet` bottom sheet.

---

## User Flow

1. User taps "Forgot Password?" on the login screen.
2. A bottom sheet slides up containing an email field (pre-filled if the user already typed an email in the login form) and a "Send Reset Link" button.
3. User confirms their email and taps the button.
4. On success: sheet dismisses, a SnackBar confirms "Password reset email sent. Check your inbox."
5. On error: an inline error message appears inside the sheet; the sheet stays open.

---

## Changes

### 1. `lib/services/auth_service.dart`

Add one method:

```dart
Future<void> sendPasswordResetEmail(String email) =>
    _auth.sendPasswordResetEmail(email: email);
```

No other changes to this file.

### 2. `lib/screens/auth/login_screen.dart`

**A. Make "Forgot Password?" tappable**

Wrap the existing `Text('Forgot Password?')` at ~line 343 with a `GestureDetector`:

```dart
GestureDetector(
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
          content: Text('Password reset email sent. Check your inbox.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  },
  child: Text('Forgot Password?', style: ...),
)
```

**B. Add `_ForgotPasswordContent` widget**

A `StatefulWidget` defined at the bottom of `login_screen.dart`. Constructor parameters: `AuthService authService`, `String initialEmail`.

Internal state:
- `TextEditingController _emailCtrl` — initialised with `initialEmail`
- `bool _loading`
- `String? _error`
- `GlobalKey<FormState> _formKey`

Layout (inside a `Form`):
1. `_OrbitField` for email (reuses existing private widget from same file)
2. Inline error container (same style as login screen's error box) — shown when `_error != null`
3. Gradient "Send Reset Link" button (same style as login screen's "Sign In" button)

Submit logic:
```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() { _loading = true; _error = null; });
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
```

Error message mapping:
| Code | Message |
|---|---|
| `invalid-email` | "Please enter a valid email address." |
| `too-many-requests` | "Too many attempts. Please try again later." |
| _(default)_ | "Failed to send reset email. Please try again." |

Note: Firebase does not throw `user-not-found` for `sendPasswordResetEmail` by default (intentional security behaviour), so no mapping is needed for unknown emails.

---

## What Does NOT Change

- No new screens or routes
- No changes to navigation/shell
- No changes to Firestore
- No changes to any provider

---

## Testing Checklist

- [ ] Tapping "Forgot Password?" opens the bottom sheet
- [ ] Email field is pre-filled when login email field has content
- [ ] Email field is empty when login email field is empty
- [ ] Submitting an invalid email format shows inline error
- [ ] Submitting a valid email dismisses the sheet and shows SnackBar
- [ ] Loading spinner shows during the async call
- [ ] Sheet can be dismissed by swiping down without sending
- [ ] On tablet/desktop the sheet renders as a centered dialog (existing `showGlassSheet` behaviour)
