<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Handle user login and issue a Sanctum token.
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ], [
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Validasi gagal.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $throttleKey = $this->throttleKey($request);

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);

            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Terlalu banyak percobaan login. Silakan coba lagi dalam {$seconds} detik.",
                'retry_after' => $seconds,
            ], 429, [
                'Retry-After' => $seconds,
            ]);
        }

        $email = strtolower(trim((string) $request->input('email')));
        $user = User::with('role')->where('email', $email)->first();

        if (! $user || ! Hash::check($request->input('password'), $user->password)) {
            RateLimiter::hit($throttleKey, 60);

            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Akun Anda dinonaktifkan. Silakan hubungi Administrator.',
            ], 403);
        }

        RateLimiter::clear($throttleKey);

        $token = $user->createToken('auth_token')->plainTextToken;
        $roleName = $user->role?->name;

        $userData = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'department' => $user->department,
            'nip' => $user->nip,
            'role' => $roleName,
            'is_active' => (bool) $user->is_active,
            'must_change_password' => (bool) $user->must_change_password,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ];

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Login berhasil.',
            'token' => $token,
            'role' => $roleName,
            'must_change_password' => (bool) $user->must_change_password,
            'user' => $userData,
            'data' => [
                'token' => $token,
                'token_type' => 'Bearer',
                'role' => $roleName,
                'must_change_password' => (bool) $user->must_change_password,
                'user' => $userData,
            ],
        ], 200);
    }

    /**
     * Change user password (e.g. on first login or self-service update).
     */
    public function changePassword(\App\Http\Requests\ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! Hash::check($request->input('current_password'), $user->password)) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Password lama tidak sesuai.',
                'errors' => [
                    'current_password' => ['Password lama tidak sesuai.'],
                ],
            ], 422);
        }

        $user->password = Hash::make($request->input('password'));
        $user->must_change_password = false;
        $user->save();

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Password berhasil diperbarui.',
            'data' => [
                'user' => new UserResource($user->loadMissing('role')),
            ],
        ], 200);
    }

    /**
     * Get the authenticated user profile.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->loadMissing('role');

        if (! $user->is_active) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Akun Anda dinonaktifkan. Silakan hubungi Administrator.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data profil berhasil diambil.',
            'data' => [
                'user' => new UserResource($user),
            ],
        ], 200);
    }

    /**
     * Log out the authenticated user by revoking the current access token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
            'data' => null,
        ], 200);
    }

    /**
     * Get the rate limiting throttle key for the request.
     */
    private function throttleKey(Request $request): string
    {
        return Str::transliterate(Str::lower((string) $request->input('email')).'|'.$request->ip());
    }
}
