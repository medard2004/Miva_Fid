# Auth Method Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a Google-created account authenticatable only via Google (never via password, never via "forgot password"), keep email/phone globally unique across both auth methods, and fix the account settings screen to reflect this.

**Architecture:** Backend is Laravel (`restaurant-loyalty-api`), table `clients`, single shared table for both classic and OAuth accounts, with `oauth_provider`/`oauth_id` nullable columns and `Client::isOAuthUser()` as the existing source-of-truth helper. Frontend is Flutter (`Miva_Fid`) talking to this API; it never shows raw backend error text — `ErrorTranslator` pattern-matches the raw message and maps it to a curated string from `ErrorMessages`. Three real bugs are fixed: (1) `SocialAuthService::findOrCreateClient()` silently attaches a Google identity onto any existing account matched by email, regardless of that account's current auth method; (2) `login()` doesn't check `oauth_provider` before checking the password hash; (3) `forgotPassword()`/`resetPassword()` don't check `oauth_provider` before issuing an OTP / writing a new password. Global uniqueness of email/phone is **already enforced** at the DB level (`unique` columns on `clients`) and in `RegisterRequest`/`UpdateProfileRequest`/`CompleteSocialProfileRequest` — no change needed there, only regression tests to lock it in.

**Tech Stack:** Laravel 11 / PHPUnit (backend), Flutter / Dart (frontend, `flutter_test` for pure-Dart unit tests).

**Spec:** requirements given directly by the user in this conversation (no separate spec file) — summarized: (1) auth method is exclusive per account and is the source of truth; (2) email/phone unique globally across both methods; (3) forgot-password must refuse Google-only accounts with the exact message "Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte."; (4) classic login must refuse Google-only accounts with a clear message; (5) account settings must hide "change password" / "create password" for Google accounts and show the connected provider instead.

## Global Constraints

- Never show raw backend error text in the Flutter UI — always go through `ErrorMessages` catalog entries (existing architectural rule documented at the top of `lib/core/errors/error_translator.dart`).
- Auth-method-denial responses from the backend must use HTTP 403 (not 401) — `AuthService._throwFromDio()` in Flutter throws `UnauthorizedException` for 401, which **drops the backend message entirely** (`ErrorTranslator` never reads its `.message`). Only 403+ (`ServerException`) carries the message through for pattern matching.
- `Client::isOAuthUser()` (`app/Models/Client.php:69-72`, `!empty($this->oauth_provider)`) is the single source of truth for auth method — every new check must use it, never infer method from presence/absence of email or phone.
- Do not add a "link accounts" feature — an email/phone collision between a classic and a Google account must always be an error, never a silent merge.

---

## Task 1: `Client::authMethodDeniedMessage()` helper

**Files:**
- Modify: `app/Models/Client.php:69-72` (right after `isOAuthUser()`)
- Test: `tests/Unit/Models/ClientAuthMethodMessageTest.php`

**Interfaces:**
- Produces: `Client::authMethodDeniedMessage(): string` — called by Tasks 2-5. Branches on `$this->isOAuthUser()`: if true, returns the Google/Apple-only message naming `$this->oauth_provider`; if false, returns the "existing password account" message. This lets both directions of the conflict (password-account tries to act like it's OAuth, OAuth-account tries to act like it has a password) share one wording source.

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Unit\Models;

use App\Models\Client;
use PHPUnit\Framework\TestCase;

class ClientAuthMethodMessageTest extends TestCase
{
    public function test_google_account_message_names_the_provider(): void
    {
        $client = new Client(['oauth_provider' => 'google']);

        $this->assertSame(
            'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.',
            $client->authMethodDeniedMessage(),
        );
    }

    public function test_apple_account_message_names_the_provider(): void
    {
        $client = new Client(['oauth_provider' => 'apple']);

        $this->assertSame(
            'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.',
            $client->authMethodDeniedMessage(),
        );
    }

    public function test_classic_account_message_points_to_password_login(): void
    {
        $client = new Client(['oauth_provider' => null]);

        $this->assertSame(
            'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.',
            $client->authMethodDeniedMessage(),
        );
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Unit/Models/ClientAuthMethodMessageTest.php`
Expected: FAIL — `Call to undefined method App\Models\Client::authMethodDeniedMessage()`

- [ ] **Step 3: Write minimal implementation**

In `app/Models/Client.php`, right after the existing `isOAuthUser()` method (line 72):

```php
    /**
     * Message affiché quand une action est refusée parce que ce compte
     * utilise une autre méthode d'authentification. `oauth_provider` reste
     * la seule source de vérité (jamais l'email ou le téléphone).
     */
    public function authMethodDeniedMessage(): string
    {
        if ($this->isOAuthUser()) {
            $provider = ucfirst((string) $this->oauth_provider);

            return "Ce compte utilise une connexion {$provider}. Connectez-vous avec {$provider} pour accéder à votre compte.";
        }

        return 'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.';
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Unit/Models/ClientAuthMethodMessageTest.php`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add app/Models/Client.php tests/Unit/Models/ClientAuthMethodMessageTest.php
git commit -m "feat: add Client::authMethodDeniedMessage() as single wording source"
```

---

## Task 2: Block password login on Google/Apple accounts

**Files:**
- Modify: `app/Http/Controllers/Api/ClientAuthController.php:97-129` (`login()`)
- Test: `tests/Feature/Auth/AuthMethodEnforcementTest.php` (new file)

**Interfaces:**
- Consumes: `Client::isOAuthUser()`, `Client::authMethodDeniedMessage()` (Task 1).

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature\Auth;

use App\Models\Client;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Tests\TestCase;

class AuthMethodEnforcementTest extends TestCase
{
    use RefreshDatabase;

    private function makeClassicClient(array $overrides = []): Client
    {
        return Client::create(array_merge([
            'uuid'       => (string) Str::uuid(),
            'first_name' => 'Ada',
            'phone'      => '+22890000001',
            'password'   => bcrypt('secret123'),
        ], $overrides));
    }

    private function makeGoogleClient(array $overrides = []): Client
    {
        return Client::create(array_merge([
            'uuid'           => (string) Str::uuid(),
            'first_name'     => 'Kofi',
            'email'          => 'kofi@example.com',
            'phone'          => '+22890000002',
            'password'       => null,
            'oauth_provider' => 'google',
            'oauth_id'       => 'google-uid-1',
        ], $overrides));
    }

    public function test_login_rejects_google_account_with_clear_message(): void
    {
        $client = $this->makeGoogleClient();

        $response = $this->postJson('/api/auth/login', [
            'phone'    => $client->phone,
            'password' => 'whatever123',
        ]);

        $response->assertStatus(403);
        $response->assertJson([
            'message' => 'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.',
        ]);
    }

    public function test_login_still_works_for_classic_account(): void
    {
        $client = $this->makeClassicClient();

        $response = $this->postJson('/api/auth/login', [
            'phone'    => $client->phone,
            'password' => 'secret123',
        ]);

        $response->assertOk();
        $response->assertJsonStructure(['access_token']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: `test_login_rejects_google_account_with_clear_message` FAILS — current code calls `Hash::check($request->password, $client->password)` with `$client->password === null`, so the response is not the expected 403 with the Google message (either a 401 "Mot de passe incorrect" or a hashing error, never the 403 we assert). `test_login_still_works_for_classic_account` passes already (regression baseline).

- [ ] **Step 3: Write minimal implementation**

In `app/Http/Controllers/Api/ClientAuthController.php`, inside `login()` (currently lines 101-117), insert the guard between the "account not found" check and the password check:

```php
        $client = Client::where('phone', $request->phone)->first();

        if (! $client) {
            $request->hitRateLimiter();

            return response()->json([
                'message' => 'Aucun compte n\'est associé à ce numéro.',
            ], 401);
        }

        if ($client->isOAuthUser()) {
            $request->hitRateLimiter();

            return response()->json([
                'message' => $client->authMethodDeniedMessage(),
            ], 403);
        }

        if (! Hash::check($request->password, $client->password)) {
            $request->hitRateLimiter();

            return response()->json([
                'message' => 'Mot de passe incorrect.',
            ], 401);
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Api/ClientAuthController.php tests/Feature/Auth/AuthMethodEnforcementTest.php
git commit -m "fix: reject password login on Google/Apple accounts with a clear message"
```

---

## Task 3: Block "forgot password" OTP for Google/Apple accounts

**Files:**
- Modify: `app/Http/Controllers/Api/ClientAuthController.php:405-423` (`forgotPassword()`)
- Test: `tests/Feature/Auth/AuthMethodEnforcementTest.php` (append)

**Interfaces:**
- Consumes: `Client::isOAuthUser()`, `Client::authMethodDeniedMessage()` (Task 1).

- [ ] **Step 1: Write the failing test**

Append to `tests/Feature/Auth/AuthMethodEnforcementTest.php`:

```php
    public function test_forgot_password_rejects_google_account_without_sending_otp(): void
    {
        $client = $this->makeGoogleClient(['email' => 'kofi2@example.com', 'phone' => '+22890000003']);

        $response = $this->postJson('/api/auth/forgot-password', [
            'phone' => $client->phone,
        ]);

        $response->assertStatus(403);
        $response->assertJson([
            'message' => 'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.',
        ]);
        $this->assertNull(Cache::get('otp_reset_' . $client->phone));
    }

    public function test_forgot_password_still_works_for_classic_account(): void
    {
        $client = $this->makeClassicClient(['phone' => '+22890000004']);

        $response = $this->postJson('/api/auth/forgot-password', [
            'phone' => $client->phone,
        ]);

        $response->assertOk();
        $this->assertNotNull(Cache::get('otp_reset_' . $client->phone));
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: `test_forgot_password_rejects_google_account_without_sending_otp` FAILS — current `forgotPassword()` generates and caches an OTP unconditionally, so the response is 200 (not 403) and the OTP cache key is set (not null).

- [ ] **Step 3: Write minimal implementation**

In `app/Http/Controllers/Api/ClientAuthController.php`, replace the start of `forgotPassword()` (currently lines 405-410):

```php
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $identifier = $request->phone ?? $request->email;

        $client = Client::where(isset($request->phone) ? 'phone' : 'email', $identifier)->first();

        if ($client && $client->isOAuthUser()) {
            return response()->json([
                'message' => $client->authMethodDeniedMessage(),
            ], 403);
        }

        $otp = (string) random_int(100000, 999999);

        Cache::put('otp_reset_' . $identifier, $otp, now()->addMinutes(10));
```

(rest of the method unchanged)

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Api/ClientAuthController.php tests/Feature/Auth/AuthMethodEnforcementTest.php
git commit -m "fix: never send a password-reset OTP for Google/Apple accounts"
```

---

## Task 4: Block password reset itself for Google/Apple accounts (defense in depth)

**Files:**
- Modify: `app/Http/Controllers/Api/ClientAuthController.php:449-477` (`resetPassword()`)
- Test: `tests/Feature/Auth/AuthMethodEnforcementTest.php` (append)

**Interfaces:**
- Consumes: `Client::isOAuthUser()`, `Client::authMethodDeniedMessage()` (Task 1).

Task 3 already prevents an OTP (and therefore a `reset_token`) from ever being issued for a Google/Apple account through the normal flow. This task guards the actual password-write endpoint directly, in case a `reset_token` ever ends up cached for such an account by another path.

- [ ] **Step 1: Write the failing test**

Append to `tests/Feature/Auth/AuthMethodEnforcementTest.php`:

```php
    public function test_reset_password_rejects_google_account_even_with_a_valid_token(): void
    {
        $client = $this->makeGoogleClient(['email' => 'kofi3@example.com', 'phone' => '+22890000005']);
        Cache::put('reset_token_' . $client->phone, 'forged-token', now()->addMinutes(15));

        $response = $this->postJson('/api/auth/reset-password', [
            'phone'                 => $client->phone,
            'reset_token'           => 'forged-token',
            'password'              => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertStatus(403);
        $this->assertNull($client->fresh()->password);
    }

    public function test_reset_password_still_works_for_classic_account(): void
    {
        $client = $this->makeClassicClient(['phone' => '+22890000006']);
        Cache::put('reset_token_' . $client->phone, 'real-token', now()->addMinutes(15));

        $response = $this->postJson('/api/auth/reset-password', [
            'phone'                 => $client->phone,
            'reset_token'           => 'real-token',
            'password'              => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ]);

        $response->assertOk();
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('newpassword123', $client->fresh()->password));
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: `test_reset_password_rejects_google_account_even_with_a_valid_token` FAILS — current `resetPassword()` writes the password unconditionally once the token matches, so the response is 200 and `$client->fresh()->password` is no longer null.

- [ ] **Step 3: Write minimal implementation**

In `app/Http/Controllers/Api/ClientAuthController.php`, inside `resetPassword()` (currently lines 460-466), insert the guard right after fetching `$client` and before updating the password:

```php
        // Trouver le client
        $client = Client::where(isset($request->phone) ? 'phone' : 'email', $identifier)->firstOrFail();

        if ($client->isOAuthUser()) {
            return response()->json([
                'message' => $client->authMethodDeniedMessage(),
            ], 403);
        }

        // Mettre à jour le mot de passe
        $client->update([
            'password' => Hash::make($request->password),
        ]);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Auth/AuthMethodEnforcementTest.php`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add app/Http/Controllers/Api/ClientAuthController.php tests/Feature/Auth/AuthMethodEnforcementTest.php
git commit -m "fix: refuse to write a password onto a Google/Apple account at the mutation point"
```

---

## Task 5: Stop silently linking Google sign-in onto an existing account by email

**Files:**
- Modify: `app/Services/Auth/SocialAuthService.php:174-188` (`findOrCreateClient()`)
- Test: `tests/Feature/Auth/SocialAuthServiceTest.php` (new file)

**Interfaces:**
- Consumes: `Client::authMethodDeniedMessage()` (Task 1).
- Produces: `findOrCreateClient()` keeps its existing signature/return shape (`array{client: Client, is_new: bool}`) for the "no conflict" paths; on a conflict it now throws `\InvalidArgumentException` (already caught by `ClientAuthController::socialLogin()` at lines 172-176, mapped to HTTP 403) instead of silently mutating the matched row.

This is the account-integrity bug: today, a Google sign-in whose email matches *any* existing client — including a classic password account, with no verification the caller owns that account — gets `oauth_provider`/`oauth_id` stamped onto that row. That produces a hybrid account (has both a password and an OAuth identity), which breaks "auth method is exclusive and is the source of truth."

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature\Auth;

use App\Models\Client;
use App\Services\Auth\SocialAuthService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class SocialAuthServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_does_not_link_google_identity_onto_existing_classic_account(): void
    {
        $classic = Client::create([
            'uuid'       => (string) Str::uuid(),
            'first_name' => 'Ada',
            'email'      => 'shared@example.com',
            'phone'      => '+22890000010',
            'password'   => bcrypt('secret123'),
        ]);

        $service = app(SocialAuthService::class);

        try {
            $service->findOrCreateClient(
                provider: 'google',
                oauthId: 'google-uid-99',
                email: 'shared@example.com',
            );
            $this->fail('Expected InvalidArgumentException was not thrown.');
        } catch (\InvalidArgumentException $e) {
            $this->assertSame(
                'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.',
                $e->getMessage(),
            );
        }

        $this->assertNull($classic->fresh()->oauth_provider);
        $this->assertNotNull($classic->fresh()->password);
    }

    public function test_creates_new_google_account_when_email_is_unused(): void
    {
        $service = app(SocialAuthService::class);

        $result = $service->findOrCreateClient(
            provider: 'google',
            oauthId: 'google-uid-100',
            email: 'fresh@example.com',
            firstName: 'Fresh',
        );

        $this->assertTrue($result['is_new']);
        $this->assertSame('google', $result['client']->oauth_provider);
    }

    public function test_finds_existing_google_account_by_oauth_id_without_touching_email_path(): void
    {
        $existing = Client::create([
            'uuid'           => (string) Str::uuid(),
            'first_name'     => 'Kofi',
            'email'          => 'kofi@example.com',
            'oauth_provider' => 'google',
            'oauth_id'       => 'google-uid-1',
        ]);

        $service = app(SocialAuthService::class);

        $result = $service->findOrCreateClient(
            provider: 'google',
            oauthId: 'google-uid-1',
            email: 'kofi@example.com',
        );

        $this->assertFalse($result['is_new']);
        $this->assertSame($existing->id, $result['client']->id);
    }

    public function test_social_login_endpoint_returns_403_when_email_belongs_to_classic_account(): void
    {
        Client::create([
            'uuid'       => (string) Str::uuid(),
            'first_name' => 'Ada',
            'email'      => 'shared2@example.com',
            'phone'      => '+22890000011',
            'password'   => bcrypt('secret123'),
        ]);

        $this->partialMock(SocialAuthService::class, function ($mock) {
            $mock->shouldReceive('validateToken')
                ->once()
                ->andReturn(['sub' => 'google-uid-200', 'email' => 'shared2@example.com', 'name' => 'Someone']);
        });

        $response = $this->postJson('/api/auth/social', [
            'provider' => 'google',
            'id_token' => 'fake-token',
            'action'   => 'signup',
        ]);

        $response->assertStatus(403);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `php artisan test tests/Feature/Auth/SocialAuthServiceTest.php`
Expected: `test_does_not_link_google_identity_onto_existing_classic_account` and `test_social_login_endpoint_returns_403_when_email_belongs_to_classic_account` FAIL — current code links instead of throwing, so no exception is raised and the HTTP endpoint returns 200/201, not 403. The other two tests already pass (regression baseline for the oauth_id lookup path).

- [ ] **Step 3: Write minimal implementation**

In `app/Services/Auth/SocialAuthService.php`, replace lines 174-188:

```php
        // 2. Si un compte existe déjà avec cet email, la méthode d'authentification
        // de ce compte reste inchangée : on ne lie jamais silencieusement une
        // identité OAuth à un compte trouvé par email (voir Client::authMethodDeniedMessage
        // — la méthode associée au compte est la seule source de vérité).
        if ($email) {
            $existing = Client::where('email', $email)->first();

            if ($existing) {
                throw new \InvalidArgumentException($existing->authMethodDeniedMessage());
            }
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `php artisan test tests/Feature/Auth/SocialAuthServiceTest.php`
Expected: PASS (4 tests)

- [ ] **Step 5: Run the full backend auth test suite**

Run: `php artisan test tests/Feature/Auth tests/Unit/Models`
Expected: PASS (all tests from Tasks 1-5)

- [ ] **Step 6: Commit**

```bash
git add app/Services/Auth/SocialAuthService.php tests/Feature/Auth/SocialAuthServiceTest.php
git commit -m "fix: never auto-link a Google/Apple identity onto an existing account by email"
```

---

## Task 6: Flutter — new error catalog entries + translations

**Files:**
- Modify: `lib/l10n/app_fr.arb:316` (insert after), `lib/l10n/app_fr.arb:321` (insert after), `lib/l10n/app_fr.arb:380` (insert before closing brace)
- Modify: `lib/l10n/app_en.arb` (same three insertion points, English text)
- Modify: `lib/core/errors/error_messages.dart` (add matching getters)
- Run: `flutter gen-l10n` (regenerates `lib/l10n/gen/app_localizations*.dart`)

**Interfaces:**
- Produces: `ErrorMessages.accountUsesGoogle`, `ErrorMessages.accountUsesApple`, `ErrorMessages.socialEmailUsesPassword`, consumed by Task 7. `AppUser.socialProviderLabel` getter, consumed by Task 8.

- [ ] **Step 1: Add ARB keys to `lib/l10n/app_fr.arb`**

After line 316 (`"errLoginFailed": ...`):
```json
  "errAccountUsesGoogle": "Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.",
  "errAccountUsesApple": "Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.",
```

After line 321 (`"errSocialAccountNotFound": ...`, now shifted +2 lines):
```json
  "errSocialEmailUsesPassword": "Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.",
```

Before the closing `}` (replace the last line, currently `"editProfilePhotoLabel": "Photo de profil"`):
```json
  "editProfilePhotoLabel": "Photo de profil",
  "editProfileConnectedVia": "Connecté via {provider}",
  "@editProfileConnectedVia": {
    "placeholders": { "provider": { "type": "String" } }
  }
```

- [ ] **Step 2: Add matching ARB keys to `lib/l10n/app_en.arb`** (same three insertion points)

```json
  "errAccountUsesGoogle": "This account uses Google sign-in. Sign in with Google to access your account.",
  "errAccountUsesApple": "This account uses Apple sign-in. Sign in with Apple to access your account.",
```
```json
  "errSocialEmailUsesPassword": "An account already exists with this email and uses a password. Sign in with your password instead.",
```
```json
  "editProfilePhotoLabel": "Profile photo",
  "editProfileConnectedVia": "Connected via {provider}",
  "@editProfileConnectedVia": {
    "placeholders": { "provider": { "type": "String" } }
  }
```

- [ ] **Step 3: Regenerate localization code**

Run: `flutter gen-l10n`
Expected: regenerates `lib/l10n/gen/app_localizations.dart`, `app_localizations_fr.dart`, `app_localizations_en.dart` with the new getters/methods, no errors.

- [ ] **Step 4: Add catalog entries to `ErrorMessages`**

In `lib/core/errors/error_messages.dart`, after the `loginFailed`/`loginSuccess` getters (near line with `// ── Connexion sociale ──`):

```dart
  static String get accountUsesGoogle => _t?.errAccountUsesGoogle ?? 'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.';

  static String get accountUsesApple => _t?.errAccountUsesApple ?? 'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.';
```

Right after `socialAccountNotFound`:

```dart
  static String get socialEmailUsesPassword => _t?.errSocialEmailUsesPassword ?? 'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.';
```

- [ ] **Step 5: Verify the app still analyzes cleanly**

Run: `flutter analyze lib/core/errors/error_messages.dart`
Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/gen lib/core/errors/error_messages.dart
git commit -m "feat: add error catalog entries for Google/Apple-only account messages"
```

---

## Task 7: Flutter — detect the new backend messages in `ErrorTranslator`

**Files:**
- Modify: `lib/core/errors/error_translator.dart:176-219` (`_fromServer()`)
- Test: `test/core/errors/error_translator_test.dart` (new file, new `test/` directory)

**Interfaces:**
- Consumes: `ErrorMessages.accountUsesGoogle`, `.accountUsesApple`, `.socialEmailUsesPassword` (Task 6).

This must run **before** the existing `if (status == 401 || status == 403) { return AppError.general(_unauthorizedMessage(context)); }` shortcut (line 183-185 today), otherwise our 403 responses get swallowed into the generic per-context fallback and the specific wording never reaches the user.

- [ ] **Step 1: Write the failing test**

Create `test/core/errors/error_translator_test.dart` (first test in the project — plain Dart, no widget pump needed):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:miva_fid/core/api/core/api_exceptions.dart';
import 'package:miva_fid/core/errors/app_error.dart';
import 'package:miva_fid/core/errors/error_messages.dart';
import 'package:miva_fid/core/errors/error_translator.dart';

void main() {
  group('ErrorTranslator — auth method conflicts', () {
    test('login: Google-only account message maps to accountUsesGoogle', () {
      final error = ServerException(
        'Ce compte utilise une connexion Google. Connectez-vous avec Google pour accéder à votre compte.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.accountUsesGoogle);
    });

    test('forgotPassword: Apple-only account message maps to accountUsesApple', () {
      final error = ServerException(
        'Ce compte utilise une connexion Apple. Connectez-vous avec Apple pour accéder à votre compte.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.forgotPassword);

      expect(result.generalMessage, ErrorMessages.accountUsesApple);
    });

    test('socialLogin: email already used by a password account maps to socialEmailUsesPassword', () {
      final error = ServerException(
        'Un compte existe déjà avec cet e-mail et utilise un mot de passe. Connectez-vous avec votre mot de passe.',
        statusCode: 403,
      );

      final result = ErrorTranslator.translate(error, context: ErrorContext.socialLogin);

      expect(result.generalMessage, ErrorMessages.socialEmailUsesPassword);
    });

    test('an unrelated 403 still falls back to the generic per-context message', () {
      final error = ServerException('Forbidden.', statusCode: 403);

      final result = ErrorTranslator.translate(error, context: ErrorContext.login);

      expect(result.generalMessage, ErrorMessages.loginInvalidCredentials);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/errors/error_translator_test.dart`
Expected: first three tests FAIL — `result.generalMessage` currently equals the generic `_unauthorizedMessage(context)` result (e.g. `ErrorMessages.loginInvalidCredentials`), not the new specific messages. The fourth test passes already (regression baseline).

- [ ] **Step 3: Write minimal implementation**

In `lib/core/errors/error_translator.dart`, inside `_fromServer()`, insert the new checks between the 429 check and the 401/403 shortcut (currently lines 180-185):

```dart
    if (status == 429 || _has(raw, ['trop de tentatives', 'too many'])) {
      return AppError.general(ErrorMessages.tooManyAttempts);
    }
    if (_has(raw, ['connexion google', 'utilise google'])) {
      return AppError.general(ErrorMessages.accountUsesGoogle);
    }
    if (_has(raw, ['connexion apple', 'utilise apple'])) {
      return AppError.general(ErrorMessages.accountUsesApple);
    }
    if (_has(raw, ['utilise un mot de passe'])) {
      return AppError.general(ErrorMessages.socialEmailUsesPassword);
    }
    if (status == 401 || status == 403) {
      return AppError.general(_unauthorizedMessage(context));
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/errors/error_translator_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/errors/error_translator.dart test/core/errors/error_translator_test.dart
git commit -m "feat: surface Google/Apple-only account errors with their own message"
```

---

## Task 8: Flutter — hide password editing for social accounts, show connected provider

**Files:**
- Modify: `lib/features/client/models/user.dart` (add `socialProviderLabel` getter, near `isSocialUser` at line 122-123)
- Modify: `lib/features/client/profile/edit_profile_screen.dart:177-184`

**Interfaces:**
- Consumes: `AppUser.isSocialUser` (existing, `user.dart:122-123`), `ErrorMessages` unaffected here.
- Produces: `AppUser.socialProviderLabel` — `'Google'` / `'Apple'` / `''`, consumed only by this task's screen edit.

No existing widget-test harness exists for this screen (no `test/` widget tests, no Riverpod/GoRouter test scaffolding anywhere in the project) and building one from scratch is out of scope for this fix — this task is implementation + manual verification instead of TDD, per the plan's constraint against introducing disproportionate new test infrastructure for a single conditional UI row.

- [ ] **Step 1: Add the provider label getter**

In `lib/features/client/models/user.dart`, right after `isSocialUser` (lines 121-123):

```dart
  /// Vrai si cet utilisateur s'est connecté via un fournisseur social.
  bool get isSocialUser =>
      authProvider == AuthProvider.google || authProvider == AuthProvider.apple;

  /// Nom lisible du fournisseur social ("Google"/"Apple"), vide pour un
  /// compte classique — utilisé pour l'indicateur "Connecté via" du profil.
  String get socialProviderLabel => switch (authProvider) {
        AuthProvider.google => 'Google',
        AuthProvider.apple => 'Apple',
        AuthProvider.phone => '',
      };
```

- [ ] **Step 2: Replace the unconditional password row**

In `lib/features/client/profile/edit_profile_screen.dart`, replace lines 177-184:

```dart
                    Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      icon: LucideIcons.lock,
                      label: t.changePasswordTitle,
                      value: '••••••••',
                      onTap: () =>
                          context.push('/client/profile/verify-password'),
                    ),
```

with:

```dart
                    Divider(height: 1, color: AppColors.border),
                    if (user?.isSocialUser ?? false)
                      _InfoRow(
                        icon: LucideIcons.shieldCheck,
                        label: t.editProfileSecurity,
                        value: t.editProfileConnectedVia(user!.socialProviderLabel),
                        onTap: () {},
                      )
                    else
                      _InfoRow(
                        icon: LucideIcons.lock,
                        label: t.changePasswordTitle,
                        value: '••••••••',
                        onTap: () =>
                            context.push('/client/profile/verify-password'),
                      ),
```

- [ ] **Step 3: Verify it analyzes cleanly**

Run: `flutter analyze lib/features/client/models/user.dart lib/features/client/profile/edit_profile_screen.dart`
Expected: No issues found.

- [ ] **Step 4: Manual verification**

Run the app (`flutter run`), sign in as a classic (phone+password) account, open Profile → Modifier le profil, confirm the "Modifier le mot de passe" row still opens the password-change flow. Then sign in (or inspect) as a Google-created account, confirm the row now reads "Sécurité" / "Connecté via Google" and does not navigate to the password-change flow.

- [ ] **Step 5: Commit**

```bash
git add lib/features/client/models/user.dart lib/features/client/profile/edit_profile_screen.dart
git commit -m "fix: hide password editing for Google/Apple accounts, show connected provider"
```

---

## Self-Review Notes

- **Spec §1 (exclusive method):** Task 2 (login), Task 5 (no silent linking) enforce this backend-side; Task 8 enforces it in the settings UI. ✅
- **Spec §2 (global uniqueness):** already enforced by DB `unique` columns + `RegisterRequest`/`UpdateProfileRequest`/`CompleteSocialProfileRequest` validation rules (verified during exploration, no code gap found) — Task 5's regression test (`test_finds_existing_google_account_by_oauth_id_without_touching_email_path`) and Task 2/3/4's classic-account regression tests lock in that nothing here broke it. ✅
- **Spec §3 (forgot password, exact message):** Task 3 (OTP never sent) + Task 4 (password never written) backend-side; Task 6/7 surface the exact wording in the UI. ✅
- **Spec §4 (classic login):** Task 2 covers "Google-only → refuse"; "compte classique → connexion normale" and "compte inexistant → message approprié" are pre-existing, unchanged, and covered by regression tests. ✅
- **Spec §5 (account settings):** Task 8. ✅
- **"Important" (method is source of truth, email/phone never bypass it):** every new check in Tasks 2-5 branches on `Client::isOAuthUser()`/`oauth_provider`, never on whether email/phone happen to match. ✅
