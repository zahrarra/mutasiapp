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
            'date' => $this->date ?? null,
            'previous_location' => $this->previous_location ?? null,
            'new_location' => $this->new_location ?? null,
            'previous_pic' => $this->previous_pic ?? null,
            'new_pic' => $this->new_pic ?? null,
            'updated_by' => $this->updated_by ?? null,
            'created_at' => $this->created_at ?? null,
        ];
    }
}
