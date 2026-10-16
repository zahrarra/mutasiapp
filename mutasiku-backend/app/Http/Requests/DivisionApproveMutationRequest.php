<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class DivisionApproveMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'pemimpin_divisi';
    }

    public function rules(): array
    {
        return [
            'action' => ['nullable', 'string', 'in:approve,reject'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if ($this->input('action') === 'reject' && empty(trim((string) $this->input('reason')))) {
                $validator->errors()->add('reason', 'Alasan penolakan (reason) wajib diisi jika pengajuan ditolak.');
            }
        });
    }

    public function messages(): array
    {
        return [
            'action.required' => 'Aksi approval wajib dipilih.',
            'action.in' => 'Aksi approval tidak valid. Pilihan: approve atau reject.',
        ];
    }

    public function isReject(): bool
    {
        return $this->input('action') === 'reject';
    }
}
