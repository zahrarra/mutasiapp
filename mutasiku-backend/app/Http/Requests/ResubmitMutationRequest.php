<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResubmitMutationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'pemohon';
    }

    public function rules(): array
    {
        return [
            'destination_location_id' => ['nullable', 'integer', 'exists:locations,id'],
            'reason' => ['nullable', 'string', 'max:1000'],
            'sk_document' => ['nullable'],
        ];
    }

    public function messages(): array
    {
        return [
            'destination_location_id.exists' => 'Lokasi tujuan yang dipilih tidak ditemukan dalam sistem.',
        ];
    }
}
