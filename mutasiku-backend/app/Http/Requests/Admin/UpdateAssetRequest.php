<?php

namespace App\Http\Requests\Admin;

use App\Models\Asset;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAssetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function rules(): array
    {
        $assetParam = $this->route('asset') ?? $this->route('id');
        $assetId = $assetParam instanceof Asset ? $assetParam->id : $assetParam;
        $currentYear = (int) date('Y');

        return [
            'asset_code' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('assets', 'asset_code')->ignore($assetId)],
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'asset_category_id' => ['sometimes', 'required', 'integer', 'exists:asset_categories,id'],
            'location_id' => ['sometimes', 'required', 'integer', 'exists:locations,id'],
            'pic_id' => ['sometimes', 'required', 'integer', 'exists:users,id'],
            'condition' => ['sometimes', 'required', 'string', 'max:50'],
            'serial_number' => ['sometimes', 'required', 'string', 'max:100', Rule::unique('assets', 'serial_number')->ignore($assetId)],
            'acquisition_year' => ['sometimes', 'required', 'integer', 'min:1900', 'max:'.($currentYear + 1)],
            'usage_year' => ['nullable', 'integer', 'min:1900', 'max:'.($currentYear + 1)],
            'is_active' => ['nullable', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'asset_code.required' => 'Kode aset wajib diisi.',
            'asset_code.unique' => 'Kode aset sudah digunakan.',
            'name.required' => 'Nama aset wajib diisi.',
            'asset_category_id.required' => 'Kategori aset wajib dipilih.',
            'asset_category_id.exists' => 'Kategori aset tidak ditemukan.',
            'location_id.required' => 'Lokasi aset wajib dipilih.',
            'location_id.exists' => 'Lokasi aset tidak ditemukan.',
            'pic_id.required' => 'Penanggung jawab (PIC) wajib dipilih.',
            'pic_id.exists' => 'User PIC tidak ditemukan.',
            'condition.required' => 'Kondisi aset wajib diisi.',
            'serial_number.required' => 'Nomor seri wajib diisi.',
            'serial_number.unique' => 'Nomor seri sudah terdaftar.',
            'acquisition_year.required' => 'Tahun perolehan wajib diisi.',
        ];
    }
}
