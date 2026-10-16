<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Location extends Model
{
    protected $fillable = [
        'name',
        'code',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function assets(): HasMany
    {
        return $this->hasMany(Asset::class);
    }

    /**
     * Memeriksa apakah lokasi adalah unit penugasan resmi (divisi atau cabang),
     * bukan fasilitas fisik atau area aset (toilet, parkiran, lobby, lantai, dll.).
     */
    public function isAssignmentUnit(): bool
    {
        $code = strtoupper((string) ($this->code ?? ''));
        $name = strtolower((string) $this->name);

        // Eksklusi fasilitas umum, lantai gedung, dan kode dummy audit
        if (str_starts_with($code, 'UMUM-') || str_starts_with($code, 'LT-') || str_starts_with($code, 'AUD_')) {
            return false;
        }

        $physicalKeywords = [
            'toilet',
            'parkir',
            'lobby',
            'lantai',
            'ruang tunggu',
            'teller',
            'atm',
            'pantry',
            'mushola',
            'musholla',
            'ruang rapat',
            'gudang',
            'ruang server',
            'kantin',
            'pos satpam',
            'koridor',
            'taman',
        ];

        foreach ($physicalKeywords as $keyword) {
            if (str_contains($name, $keyword)) {
                return false;
            }
        }

        // Whitelist berdasarkan prefiks kode resmi atau kata kunci divisi/cabang
        if (str_starts_with($code, 'CAB-') || str_starts_with($code, 'RG-') || str_starts_with($code, 'DIV-')) {
            return true;
        }

        return str_contains($name, 'divisi') ||
            str_contains($name, 'cabang') ||
            str_contains($name, 'kcu') ||
            str_contains($name, 'siber');
    }
}