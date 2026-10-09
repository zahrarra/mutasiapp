<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Mutation extends Model
{
    protected $fillable = [
        'ticket_number',
        'asset_id',
        'applicant_id',
        'origin_location_id',
        'destination_location_id',
        'current_pic_id',
        'target_pic_id',
        'is_asset_moves_with_applicant',
        'reason',
        'sk_document',
        'sk_document_name',
        'status',
        'return_reason',
        'rejection_reason',
        'discrepancy_reason',
        'verified_at',
        'verified_by',
        'approved_at',
        'approved_by',
        'rejected_at',
        'rejected_by',
        'confirmed_at',
    ];

    protected $casts = [
        'is_asset_moves_with_applicant' => 'boolean',
        'verified_at' => 'datetime',
        'approved_at' => 'datetime',
        'rejected_at' => 'datetime',
        'confirmed_at' => 'datetime',
    ];

    public function asset(): BelongsTo
    {
        return $this->belongsTo(Asset::class);
    }

    public function applicant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'applicant_id');
    }

    public function originLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'origin_location_id');
    }

    public function destinationLocation(): BelongsTo
    {
        return $this->belongsTo(Location::class, 'destination_location_id');
    }

    public function currentPic(): BelongsTo
    {
        return $this->belongsTo(User::class, 'current_pic_id');
    }

    public function targetPic(): BelongsTo
    {
        return $this->belongsTo(User::class, 'target_pic_id');
    }

    public function verifiedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function rejectedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    public function histories(): HasMany
    {
        return $this->hasMany(MutationHistory::class);
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(MutationStatusHistory::class);
    }

    /**
     * Scope a query to only include active mutations.
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->whereNotIn('status', ['selesai', 'ditolak']);
    }
}
