<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AssetResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $activeMutation = $this->relationLoaded('mutations')
            ? $this->mutations->first()
            : $this->mutations()->active()->first();

        return [
            'id' => $this->id,
            'asset_code' => $this->asset_code,
            'name' => $this->name,
            'asset_category_id' => $this->asset_category_id,
            'category' => new AssetCategoryResource($this->whenLoaded('category')),
            'location_id' => $this->location_id,
            'location' => new LocationResource($this->whenLoaded('location')),
            'pic_id' => $this->pic_id,
            'pic' => new UserResource($this->whenLoaded('pic')),
            'condition' => $this->condition,
            'serial_number' => $this->serial_number,
            'acquisition_year' => $this->acquisition_year,
            'usage_year' => $this->usage_year,
            'is_active' => (bool) $this->is_active,
            'has_active_mutation' => $activeMutation !== null,
            'active_mutation_ticket' => $activeMutation?->ticket_number,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
