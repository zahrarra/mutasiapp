<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class AssetVerifyMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'bagian_aset';
    }

    public function rules(): array
    {
        return [
            'action' => ['required', 'string', 'in:verify,return'],
            'target_pic_id' => ['nullable', 'integer', 'exists:users,id'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($this->input('action') === 'return' && empty(trim((string) $this->input('reason')))) {
                $validator->errors()->add('reason', 'Alasan pengembalian (reason) wajib diisi jika pengajuan dikembalikan.');
            }
        });
    }

    public function messages(): array
    {
        return [
            'action.required' => 'Aksi verifikasi aset wajib dipilih.',
            'action.in' => 'Aksi verifikasi aset tidak valid. Pilihan: verify atau return.',
            'target_pic_id.exists' => 'User penanggung jawab baru (target_pic_id) tidak ditemukan.',
        ];
    }

    public function isReturn(): bool
    {
        return $this->input('action') === 'return';
    }
}
