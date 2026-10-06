<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AssetHistoryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id ?? null,
            'ticket_number' => $this->ticket_number ?? null,
            'date' => $this->date?->toISOString() ?? (string) $this->date,
            'previous_location_id' => $this->previous_location_id ?? null,
            'new_location_id' => $this->new_location_id ?? null,
            'previous_pic_id' => $this->previous_pic_id ?? null,
            'new_pic_id' => $this->new_pic_id ?? null,
            'updated_by' => $this->updated_by ?? null,
            'created_at' => $this->created_at?->toISOString() ?? (string) $this->created_at,
            'previous_location' => new LocationResource($this->whenLoaded('previousLocation')),
            'new_location' => new LocationResource($this->whenLoaded('newLocation')),
            'previous_pic' => new UserResource($this->whenLoaded('previousPic')),
            'new_pic' => new UserResource($this->whenLoaded('newPic')),
            'updater' => new UserResource($this->whenLoaded('updater')),
        ];
    }
}
