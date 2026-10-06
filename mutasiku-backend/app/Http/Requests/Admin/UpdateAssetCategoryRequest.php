<?php

namespace App\Http\Requests\Admin;

use App\Models\AssetCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAssetCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function rules(): array
    {
        $categoryParam = $this->route('asset_category') ?? $this->route('id');
        $categoryId = $categoryParam instanceof AssetCategory ? $categoryParam->id : $categoryParam;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'code' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('asset_categories', 'code')->ignore($categoryId)],
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
