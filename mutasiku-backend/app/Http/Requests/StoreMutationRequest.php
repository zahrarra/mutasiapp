<?php

namespace App\Http\Requests;

use App\Models\Asset;
use App\Models\Mutation;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class StoreMutationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $user = $this->user()?->loadMissing('role');

        return $user?->role?->name === 'pemohon';
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'asset_id' => ['required', 'integer', 'exists:assets,id'],
            'destination_location_id' => ['required_without:target_location_id', 'nullable', 'integer', 'exists:locations,id'],
            'target_location_id' => ['required_without:destination_location_id', 'nullable', 'integer', 'exists:locations,id'],
            'reason' => ['required', 'string', 'max:1000'],
            'sk_document' => ['required_without:sk_sdm', 'nullable'],
            'sk_sdm' => ['required_without:sk_document', 'nullable'],
            'asset_moves_with_applicant' => ['nullable', 'boolean'],
            'is_asset_moves_with_applicant' => ['nullable', 'boolean'],
            'target_pic_id' => ['nullable', 'integer'],
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'asset_id.required' => 'Aset wajib dipilih.',
            'asset_id.exists' => 'Aset yang dipilih tidak ditemukan dalam sistem.',
            'destination_location_id.required_without' => 'Lokasi tujuan wajib dipilih.',
            'target_location_id.required_without' => 'Lokasi tujuan wajib dipilih.',
            'reason.required' => 'Alasan mutasi wajib diisi.',
            'sk_document.required_without' => 'Surat Keputusan (SK) SDM wajib dilampirkan.',
            'sk_sdm.required_without' => 'Surat Keputusan (SK) SDM wajib dilampirkan.',
        ];
    }

    /**
     * Configure the validator instance.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $user = $this->user();
            $assetId = $this->input('asset_id');

            if (! $assetId) {
                return;
            }

            $asset = Asset::find($assetId);
            if (! $asset) {
                return;
            }

            // Aturan Bisnis 2 PRD: Hanya pemegang aset saat ini yang dapat mengajukan mutasi
            if ($asset->pic_id !== $user->id) {
                $validator->errors()->add('asset_id', 'Hanya pemegang aset saat ini yang dapat mengajukan mutasi.');
            }

            // Aturan Bisnis 4 PRD: Satu aset tidak boleh memiliki lebih dari satu mutasi aktif
            $hasActiveMutation = Mutation::where('asset_id', $asset->id)
                ->active()
                ->exists();

            if ($hasActiveMutation) {
                $validator->errors()->add('asset_id', 'Aset ini sedang dalam proses mutasi aktif dan tidak dapat diajukan kembali.');
            }
        });
    }

    /**
     * Helper to get normalized destination location ID.
     */
    public function getDestinationLocationId(): int
    {
        return (int) ($this->input('destination_location_id') ?? $this->input('target_location_id'));
    }

    /**
     * Helper to get normalized SK document string/path.
     */
    public function getSkDocument(): string
    {
        if ($this->hasFile('sk_document')) {
            return $this->file('sk_document')->store('documents/sk_sdm', 'public');
        }

        if ($this->hasFile('sk_sdm')) {
            return $this->file('sk_sdm')->store('documents/sk_sdm', 'public');
        }

        return (string) ($this->input('sk_document') ?? $this->input('sk_sdm'));
    }

    /**
     * Helper to determine whether the asset moves with the applicant.
     */
    public function isMovingWithApplicant(): bool
    {
        if ($this->has('asset_moves_with_applicant')) {
            return $this->boolean('asset_moves_with_applicant');
        }

        if ($this->has('is_asset_moves_with_applicant')) {
            return $this->boolean('is_asset_moves_with_applicant');
        }

        return true;
    }
}
