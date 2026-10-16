<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreAssetCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:50', 'unique:asset_categories,code'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama kategori aset wajib diisi.',
            'code.required' => 'Kode kategori aset wajib diisi.',
            'code.unique' => 'Kode kategori aset sudah digunakan.',
        ];
    }
}
