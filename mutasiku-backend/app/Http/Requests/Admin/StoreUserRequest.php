<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreUserRequest extends FormRequest
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
        if ($this->filled('role_id')) {
            $role = \App\Models\Role::find($this->input('role_id'));
            if ($role && in_array($role->name, ['bagian_aset', 'pemimpin_divisi', 'operator'], true)) {
                $this->merge(['department' => 'Divisi Umum dan Aset']);
            }
        }
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'role_id' => ['required', 'integer', 'exists:roles,id', $this->singletonRoleRule()],
            'role' => ['nullable', 'string'],
            'department' => ['nullable', 'string', 'max:255'],
            'nip' => ['nullable', 'string', 'max:50', 'unique:users,nip'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }

    /**
     * Role Admin, Operator, dan Pemimpin Divisi masing-masing hanya boleh
     * dimiliki oleh 1 user. Tolak pembuatan user baru kalau role tersebut
     * sudah dipakai user lain.
     */
    private function singletonRoleRule(): \Closure
    {
        return function (string $attribute, mixed $value, \Closure $fail) {
            $role = \App\Models\Role::find($value);
            if (! $role || ! in_array($role->name, ['admin', 'operator', 'pemimpin_divisi'], true)) {
                return;
            }
            if (\App\Models\User::where('role_id', $value)->exists()) {
                $fail('Role ini hanya boleh dimiliki oleh satu user dan sudah ada user dengan role tersebut.');
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
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal 6 karakter.',
            'role_id.required' => 'Role wajib dipilih.',
            'role_id.exists' => 'Role yang dipilih tidak ditemukan.',
            'nip.unique' => 'NIP sudah terdaftar.',
        ];
    }
}
