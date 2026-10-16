<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReportDiscrepancyMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'pemohon';
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'min:3', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'Alasan ketidaksesuaian (reason) wajib diisi.',
            'reason.min' => 'Alasan ketidaksesuaian minimal 3 karakter.',
        ];
    }
}
