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
            'sk_document' => ['nullable', 'file', 'mimes:pdf', 'max:30720'],
        ];
    }

    public function messages(): array
    {
        return [
            'destination_location_id.exists' => 'Lokasi tujuan yang dipilih tidak ditemukan dalam sistem.',
            'sk_document.file' => 'Berkas SK SDM harus berupa dokumen yang valid.',
            'sk_document.mimes' => 'Berkas SK SDM harus berupa dokumen dengan format PDF.',
            'sk_document.max' => 'Ukuran berkas SK SDM tidak boleh melebihi 30 MB.',
        ];
    }

    /**
     * Helper to get uploaded SK document path, or null if no new file is uploaded.
     */
    public function getSkDocument(): ?string
    {
        if ($this->hasFile('sk_document')) {
            return $this->file('sk_document')->store('documents/sk_sdm', 'public');
        }

        return null;
    }

    /**
     * Helper to get original file name of uploaded SK document if present.
     */
    public function getSkDocumentOriginalName(): ?string
    {
        if ($this->hasFile('sk_document')) {
            return $this->file('sk_document')->getClientOriginalName();
        }

        return null;
    }
}
