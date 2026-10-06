<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Asset extends Model
{
    protected $fillable = [
        'asset_code',
        'name',
        'asset_category_id',
        'location_id',
        'pic_id',
        'condition',
        'serial_number',
        'acquisition_year',
        'usage_year',
        'is_active',
    ];

    protected $casts = [
        'acquisition_year' => 'integer',
        'usage_year' => 'integer',
        'is_active' => 'boolean',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(AssetCategory::class, 'asset_category_id');
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(Location::class);
    }

    public function pic(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pic_id');
    }

    public function mutations(): HasMany
    {
        return $this->hasMany(Mutation::class);
    }

    public function mutationHistories(): HasMany
    {
        return $this->hasMany(MutationHistory::class);
    }
}
