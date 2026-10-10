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
     * Resolusi nama petugas Operator yang memverifikasi pengajuan.
     * Mengutamakan riwayat tindakan Operator atau relasi verifiedBy.
     */
    public function resolveVerifiedByName(): ?string
    {
        if ($this->relationLoaded('statusHistories')) {
            $history = $this->statusHistories
                ->where('role', 'operator')
                ->whereIn('action', ['verify', 'forward'])
                ->last();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        } else {
            $history = $this->statusHistories()
                ->where('role', 'operator')
                ->whereIn('action', ['verify', 'forward'])
                ->with('user')
                ->latest('id')
                ->first();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        }

        if ($this->relationLoaded('verifiedBy') && $this->verifiedBy?->name) {
            return $this->verifiedBy->name;
        }

        if ($this->verified_by) {
            return User::find($this->verified_by)?->name;
        }

        return null;
    }

    /**
     * Resolusi nama petugas Bagian Aset yang memverifikasi fisik/data aset.
     * Mengutamakan riwayat tindakan bagian_aset.
     */
    public function resolveAssetVerifiedByName(): ?string
    {
        if ($this->relationLoaded('statusHistories')) {
            $history = $this->statusHistories
                ->where('role', 'bagian_aset')
                ->whereIn('action', ['verify_asset', 'verify', 'update'])
                ->last();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        } else {
            $history = $this->statusHistories()
                ->where('role', 'bagian_aset')
                ->whereIn('action', ['verify_asset', 'verify', 'update'])
                ->with('user')
                ->latest('id')
                ->first();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        }

        if ($this->relationLoaded('approvedBy') && $this->approvedBy) {
            if ($this->approvedBy->role?->name === 'bagian_aset') {
                return $this->approvedBy->name;
            }
        } elseif ($this->approved_by) {
            $user = User::with('role')->find($this->approved_by);
            if ($user && $user->role?->name === 'bagian_aset') {
                return $user->name;
            }
        }

        return null;
    }

    /**
     * Resolusi nama Kadiv / Pemimpin Divisi yang memberikan persetujuan (approval).
     * Mengutamakan riwayat tindakan pemimpin_divisi dengan aksi approve.
     */
    public function resolveKadivApprovedByName(): ?string
    {
        if ($this->relationLoaded('statusHistories')) {
            $history = $this->statusHistories
                ->where('role', 'pemimpin_divisi')
                ->where('action', 'approve')
                ->last();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        } else {
            $history = $this->statusHistories()
                ->where('role', 'pemimpin_divisi')
                ->where('action', 'approve')
                ->with('user')
                ->latest('id')
                ->first();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        }

        if ($this->relationLoaded('approvedBy') && $this->approvedBy) {
            if ($this->approvedBy->role?->name === 'pemimpin_divisi') {
                return $this->approvedBy->name;
            }
        } elseif ($this->approved_by) {
            $user = User::with('role')->find($this->approved_by);
            if ($user && $user->role?->name === 'pemimpin_divisi') {
                return $user->name;
            }
        }

        return null;
    }

    /**
     * Resolusi nama peninjau yang menolak pengajuan mutasi.
     */
    public function resolveRejectedByName(): ?string
    {
        if ($this->relationLoaded('statusHistories')) {
            $history = $this->statusHistories
                ->where('action', 'reject')
                ->last();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        } else {
            $history = $this->statusHistories()
                ->where('action', 'reject')
                ->with('user')
                ->latest('id')
                ->first();
            if ($history?->user?->name) {
                return $history->user->name;
            }
        }

        if ($this->relationLoaded('rejectedBy') && $this->rejectedBy?->name) {
            return $this->rejectedBy->name;
        }

        if ($this->rejected_by) {
            return User::find($this->rejected_by)?->name;
        }

        return null;
    }

    /**
     * Scope a query to only include active mutations.
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->whereNotIn('status', ['selesai', 'ditolak']);
    }
}
