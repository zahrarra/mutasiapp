<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class ConfirmMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'pemohon';
    }

    public function rules(): array
    {
        return [
            'confirmation' => ['nullable', 'string', 'in:sesuai,tidak_sesuai'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            if (! $this->isSesuai() && empty(trim((string) $this->input('reason')))) {
                $validator->errors()->add('reason', 'Alasan ketidaksesuaian (reason) wajib diisi jika hasil konfirmasi tidak sesuai.');
            }
        });
    }

    public function messages(): array
    {
        return [
            'confirmation.in' => 'Hasil konfirmasi tidak valid. Pilihan: sesuai atau tidak_sesuai.',
        ];
    }

    public function isSesuai(): bool
    {
        return $this->input('confirmation', 'sesuai') === 'sesuai';
    }
}
