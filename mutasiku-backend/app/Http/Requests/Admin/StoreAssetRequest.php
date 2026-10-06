<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreAssetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->loadMissing('role')?->role?->name === 'admin';
    }

    public function rules(): array
    {
        $currentYear = (int) date('Y');

        return [
            'asset_code' => ['required', 'string', 'max:50', 'unique:assets,asset_code'],
            'name' => ['required', 'string', 'max:255'],
            'asset_category_id' => ['required', 'integer', 'exists:asset_categories,id'],
            'location_id' => ['required', 'integer', 'exists:locations,id'],
            'pic_id' => ['required', 'integer', 'exists:users,id'],
            'condition' => ['required', 'string', 'max:50'],
            'serial_number' => ['required', 'string', 'max:100', 'unique:assets,serial_number'],
            'acquisition_year' => ['required', 'integer', 'min:1900', 'max:'.($currentYear + 1)],
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
