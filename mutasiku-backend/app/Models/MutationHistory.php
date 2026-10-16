<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MutationHistory extends Model
{
    protected $fillable = [
        'asset_id',
        'mutation_id',
        'ticket_number',
        'date',
        'previous_location_id',
        'new_location_id',
        'previous_pic_id',
        'new_pic_id',
        'updated_by',
        'field_changed',
        'old_value',
        'new_value',
        'changed_by',
        'changed_at',
    ];

    protected $casts = [
        'date' => 'datetime',
        'changed_at' => 'datetime',
    ];

    public function asset(): BelongsTo
    {
        return $this->belongsTo(Asset::class);
    }

    public function mutation(): BelongsTo
    {
        return $this->belongsTo(Mutation::class);
    }

    public function previousLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'previous_location_id');
    }

    public function newLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'new_location_id');
    }

    public function previousPic(): BelongsTo
    {
        return $this->belongsTo(User::class, 'previous_pic_id');
    }

    public function newPic(): BelongsTo
    {
        return $this->belongsTo(User::class, 'new_pic_id');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
