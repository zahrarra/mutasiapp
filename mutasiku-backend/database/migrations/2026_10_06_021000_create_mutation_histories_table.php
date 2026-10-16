<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('mutation_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('asset_id')
                ->constrained('assets')
                ->cascadeOnDelete();

            $table->foreignId('mutation_id')
                ->nullable()
                ->constrained('mutations')
                ->nullOnDelete();

            $table->string('ticket_number');
            $table->dateTime('date');

            $table->foreignId('previous_location_id')
                ->constrained('locations')
                ->restrictOnDelete();

            $table->foreignId('new_location_id')
                ->constrained('locations')
                ->restrictOnDelete();

            $table->foreignId('previous_pic_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->foreignId('new_pic_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->foreignId('updated_by')
                ->constrained('users')
                ->restrictOnDelete();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mutation_histories');
    }
};
