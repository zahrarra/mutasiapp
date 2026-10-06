<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class OperatorVerifyMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'operator';
    }

    public function rules(): array
    {
        return [
            'action' => ['required', 'string', 'in:verify,return'],
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
            'action.required' => 'Aksi verifikasi wajib dipilih.',
            'action.in' => 'Aksi verifikasi tidak valid. Pilihan: verify atau return.',
        ];
    }

    public function isReturn(): bool
    {
        return $this->input('action') === 'return';
    }
}
