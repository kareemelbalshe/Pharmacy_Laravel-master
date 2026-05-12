<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create a default admin user
        $admin = \App\Models\User::create([
            'name' => 'Admin User',
            'email' => 'admin@admin.com',
            'phone' => '01234567890',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
            'user_type' => 'admin',
        ]);

        \App\Models\Admin::create([
            'user_id' => $admin->id,
            'name' => 'Admin User',
            'email' => 'admin@admin.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
        ]);

        // Call other seeders
        $this->call([
            DiseaseSeeder::class,
        ]);
    }
}
