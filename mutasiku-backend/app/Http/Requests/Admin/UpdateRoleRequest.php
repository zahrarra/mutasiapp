<?php

namespace App\Http\Requests\Admin;

use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRoleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function rules(): array
    {
        $roleParam = $this->route('role') ?? $this->route('id');
        $roleId = $roleParam instanceof Role ? $roleParam->id : $roleParam;

        return [
            'name' => ['required', 'string', 'max:50', Rule::unique('roles', 'name')->ignore($roleId)],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama role wajib diisi.',
            'name.unique' => 'Nama role sudah terdaftar.',
        ];
    }
}
