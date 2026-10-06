<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MutationStatusHistory extends Model
{
    protected $fillable = [
        'mutation_id',
        'user_id',
        'role',
        'action',
        'status_from',
        'status_to',
        'notes',
    ];

    public function mutation(): BelongsTo
    {
        return $this->belongsTo(Mutation::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
