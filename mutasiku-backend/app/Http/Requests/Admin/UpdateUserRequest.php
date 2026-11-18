<?php

namespace App\Http\Requests\Admin;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function prepareForValidation(): void
    {
        if (! $this->filled('role_id') && $this->filled('role')) {
            $roleName = strtolower(trim((string) $this->input('role')));
            if ($roleName === 'kadiv') {
                $roleName = 'pemimpin_divisi';
            }
            $role = \App\Models\Role::where('name', $roleName)->first();
            if ($role) {
                $this->merge(['role_id' => $role->id]);
            }
        }

        // Bagian Aset, Pemimpin Divisi, dan Operator sudah ditetapkan di
        // Divisi Umum dan Aset — divisinya tidak bisa dipilih bebas, paksa
        // nilainya di sini supaya API tidak bisa menyimpan kombinasi yang salah.
        // Kalau role tidak dikirim, pakai role user yang sudah ada —
        // jadi data lama yang divisinya salah ikut terkoreksi saat diedit.
        $roleId = $this->input('role_id');
        if (! $roleId) {
            $userParam = $this->route('user') ?? $this->route('id');
            $existing = $userParam instanceof User
                ? $userParam
                : User::find($userParam);
            $roleId = $existing?->role_id;
        }
        if ($roleId) {
            $role = \App\Models\Role::find($roleId);
            if ($role && in_array($role->name, ['bagian_aset', 'pemimpin_divisi', 'operator'], true)) {
                $this->merge(['department' => 'Divisi Umum dan Aset']);
            }
        }
    }

    public function rules(): array
    {
        $userParam = $this->route('user') ?? $this->route('id');
        $userId = $userParam instanceof User ? $userParam->id : $userParam;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => ['sometimes', 'required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($userId)],
            'password' => ['nullable', 'string', 'min:6'],
            'role_id' => ['sometimes', 'required', 'integer', 'exists:roles,id', $this->singletonRoleRule($userId)],
            'role' => ['nullable', 'string'],
            'department' => ['nullable', 'string', 'max:255'],
            'nip' => ['nullable', 'string', 'max:50', Rule::unique('users', 'nip')->ignore($userId)],
            'is_active' => ['nullable', 'boolean'],
        ];
    }

    /**
     * Role Admin, Operator, dan Pemimpin Divisi masing-masing hanya boleh
     * dimiliki oleh 1 user. Tolak perubahan role kalau role tersebut sudah
     * dipakai user lain (user yang sedang diedit dikecualikan).
     */
    private function singletonRoleRule(mixed $ignoreUserId = null): \Closure
    {
        return function (string $attribute, mixed $value, \Closure $fail) use ($ignoreUserId) {
            $role = \App\Models\Role::find($value);
            if (! $role || ! in_array($role->name, ['admin', 'operator', 'pemimpin_divisi'], true)) {
                return;
            }
            $query = \App\Models\User::where('role_id', $value);
            if ($ignoreUserId) {
                $query->where('id', '!=', $ignoreUserId);
            }
            if ($query->exists()) {
                $fail('Role ini hanya boleh dimiliki oleh satu user dan sudah ada user lain dengan role tersebut.');
            }
        };
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama user wajib diisi.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email sudah digunakan.',
            'password.min' => 'Password minimal 6 karakter.',
            'role_id.required' => 'Role wajib dipilih.',
            'role_id.exists' => 'Role yang dipilih tidak ditemukan.',
            'nip.unique' => 'NIP sudah terdaftar.',
        ];
    }
}
