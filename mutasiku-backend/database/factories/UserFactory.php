<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    public function configure(): static
    {
        return $this->afterCreating(function (User $user) {
            if ($user->department === null && $user->role_id) {
                $role = \App\Models\Role::find($user->role_id);
                if ($role && in_array($role->name, ['admin', 'operator', 'bagian_aset', 'pemimpin_divisi'])) {
                    $user->update(['department' => 'Umum & Aset']);
                }
            }
        });
    }

    public function admin(): static
    {
        return $this->state(fn (array $attributes) => [
            'role_id' => \App\Models\Role::where('name', 'admin')->value('id'),
            'department' => 'Umum & Aset',
        ]);
    }

    public function operator(): static
    {
        return $this->state(fn (array $attributes) => [
            'role_id' => \App\Models\Role::where('name', 'operator')->value('id'),
            'department' => 'Umum & Aset',
        ]);
    }

    public function bagianAset(): static
    {
        return $this->state(fn (array $attributes) => [
            'role_id' => \App\Models\Role::where('name', 'bagian_aset')->value('id'),
            'department' => 'Umum & Aset',
        ]);
    }

    public function kadiv(): static
    {
        return $this->state(fn (array $attributes) => [
            'role_id' => \App\Models\Role::where('name', 'pemimpin_divisi')->value('id'),
            'department' => 'Umum & Aset',
        ]);
    }
}
