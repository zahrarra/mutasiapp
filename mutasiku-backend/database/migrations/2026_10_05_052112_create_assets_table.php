<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assets', function (Blueprint $table) {
            $table->id();

            $table->string('asset_code')->unique();
            $table->string('name');

            $table->foreignId('asset_category_id')
                ->constrained('asset_categories')
                ->restrictOnDelete();

            $table->foreignId('location_id')
                ->constrained('locations')
                ->restrictOnDelete();

            $table->foreignId('pic_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->string('condition');

            $table->string('serial_number')->unique();

            $table->unsignedInteger('acquisition_year');

            $table->unsignedInteger('usage_year')->nullable();

            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assets');
    }
};