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
        Schema::table('mutations', function (Blueprint $table) {
            $table->text('discrepancy_reason')->nullable()->after('rejection_reason');
            $table->timestamp('verified_at')->nullable()->after('discrepancy_reason');
            $table->foreignId('verified_by')->nullable()->after('verified_at')->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable()->after('verified_by');
            $table->foreignId('approved_by')->nullable()->after('approved_at')->constrained('users')->nullOnDelete();
            $table->timestamp('rejected_at')->nullable()->after('approved_by');
            $table->foreignId('rejected_by')->nullable()->after('rejected_at')->constrained('users')->nullOnDelete();
            $table->timestamp('confirmed_at')->nullable()->after('rejected_by');
        });

        Schema::table('mutation_histories', function (Blueprint $table) {
            $table->string('field_changed')->nullable()->after('updated_by');
            $table->text('old_value')->nullable()->after('field_changed');
            $table->text('new_value')->nullable()->after('old_value');
            $table->foreignId('changed_by')->nullable()->after('new_value')->constrained('users')->nullOnDelete();
            $table->timestamp('changed_at')->nullable()->after('changed_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('mutation_histories', function (Blueprint $table) {
            $table->dropForeign(['changed_by']);
            $table->dropColumn(['field_changed', 'old_value', 'new_value', 'changed_by', 'changed_at']);
        });

        Schema::table('mutations', function (Blueprint $table) {
            $table->dropForeign(['verified_by']);
            $table->dropForeign(['approved_by']);
            $table->dropForeign(['rejected_by']);
            $table->dropColumn([
                'discrepancy_reason',
                'verified_at',
                'verified_by',
                'approved_at',
                'approved_by',
                'rejected_at',
                'rejected_by',
                'confirmed_at',
            ]);
        });
    }
};
