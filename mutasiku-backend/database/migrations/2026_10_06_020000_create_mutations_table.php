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
        Schema::create('mutations', function (Blueprint $table) {
            $table->id();
            $table->string('ticket_number')->unique();

            $table->foreignId('asset_id')
                ->constrained('assets')
                ->restrictOnDelete();

            $table->foreignId('applicant_id')
                ->constrained('users')
                ->restrictOnDelete();

            $table->foreignId('origin_location_id')
                ->constrained('locations')
                ->restrictOnDelete();

            $table->foreignId('destination_location_id')
                ->constrained('locations')
                ->restrictOnDelete();

            $table->foreignId('current_pic_id')
                ->nullable()
                ->constrained('users')
                ->restrictOnDelete();

            $table->foreignId('target_pic_id')
                ->nullable()
                ->constrained('users')
                ->restrictOnDelete();

            $table->boolean('is_asset_moves_with_applicant')->default(true);
            $table->text('reason');
            $table->string('sk_document');
            $table->string('status')->default('diajukan');

            $table->text('return_reason')->nullable();
            $table->text('rejection_reason')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mutations');
    }
};
