<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MutationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'mutation_id' => $this->id,
            'ticket_number' => $this->ticket_number,
            'asset_id' => $this->asset_id,
            'applicant_id' => $this->applicant_id,
            'origin_location_id' => $this->origin_location_id,
            'destination_location_id' => $this->destination_location_id,
            'current_pic_id' => $this->current_pic_id,
            'target_pic_id' => $this->target_pic_id,
            'is_asset_moves_with_applicant' => (bool) $this->is_asset_moves_with_applicant,
            'reason' => $this->reason,
            'sk_document' => $this->sk_document,
            'sk_document_name' => $this->sk_document_name ?? ($this->sk_document ? basename($this->sk_document) : null),
            'document_name' => $this->sk_document_name ?? ($this->sk_document ? basename($this->sk_document) : null),
            'status' => $this->status,
            'return_reason' => $this->return_reason,
            'rejection_reason' => $this->rejection_reason,
            'discrepancy_reason' => $this->discrepancy_reason,
            'verified_at' => $this->verified_at?->toISOString() ?? (string) $this->verified_at,
            'verified_by' => $this->resolveVerifiedByName() ?? ($this->verified_by && !is_numeric($this->verified_by) ? (string) $this->verified_by : null),
            'verified_by_id' => is_numeric($this->verified_by) ? (int) $this->verified_by : null,
            'verified_by_user' => $this->whenLoaded('verifiedBy', fn () => new UserResource($this->verifiedBy)),
            'approved_at' => $this->approved_at?->toISOString() ?? (string) $this->approved_at,
            'asset_verified_at' => $this->approved_at?->toISOString() ?? (string) $this->approved_at,
            'approved_by' => $this->resolveKadivApprovedByName() ?? ($this->approved_by && !is_numeric($this->approved_by) ? (string) $this->approved_by : null),
            'approved_by_id' => is_numeric($this->approved_by) ? (int) $this->approved_by : null,
            'approved_by_user' => $this->whenLoaded('approvedBy', fn () => new UserResource($this->approvedBy)),
            'asset_verified_by' => $this->resolveAssetVerifiedByName(),
            'kadiv_approved_by' => $this->resolveKadivApprovedByName(),
            'rejected_at' => $this->rejected_at?->toISOString() ?? (string) $this->rejected_at,
            'rejected_by' => $this->resolveRejectedByName() ?? ($this->rejected_by && !is_numeric($this->rejected_by) ? (string) $this->rejected_by : null),
            'rejected_by_id' => is_numeric($this->rejected_by) ? (int) $this->rejected_by : null,
            'rejected_by_user' => $this->whenLoaded('rejectedBy', fn () => new UserResource($this->rejectedBy)),
            'kadiv_rejected_by' => $this->resolveRejectedByName(),
            'staff_updated_by' => $this->resolveAssetVerifiedByName(),
            'confirmed_at' => $this->confirmed_at?->toISOString() ?? (string) $this->confirmed_at,
            'created_at' => $this->created_at?->toISOString() ?? (string) $this->created_at,
            'updated_at' => $this->updated_at?->toISOString() ?? (string) $this->updated_at,
            'asset' => new AssetResource($this->whenLoaded('asset')),
            'applicant' => new UserResource($this->whenLoaded('applicant')),
            'origin_location' => new LocationResource($this->whenLoaded('originLocation')),
            'destination_location' => new LocationResource($this->whenLoaded('destinationLocation')),
            'current_pic' => new UserResource($this->whenLoaded('currentPic')),
            'target_pic' => new UserResource($this->whenLoaded('targetPic')),
        ];
    }
}
