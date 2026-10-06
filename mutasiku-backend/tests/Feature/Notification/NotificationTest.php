<?php

namespace Tests\Feature\Notification;

use App\Models\Role;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Notification;
use Tests\TestCase;

class DummyTestNotification extends Notification
{
    use Queueable;

    public function __construct(
        public string $title = 'Status Mutasi Berubah',
        public string $message = 'Pengajuan mutasi Anda telah diverifikasi oleh Operator.'
    ) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'title' => $this->title,
            'message' => $this->message,
        ];
    }
}

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    private function createRole(string $name = 'pemohon'): Role
    {
        return Role::firstOrCreate(['name' => $name]);
    }

    private function createUser(string $roleName = 'pemohon'): User
    {
        $role = $this->createRole($roleName);

        return User::factory()->create([
            'role_id' => $role->id,
            'is_active' => true,
        ]);
    }

    public function test_endpoints_require_authentication(): void
    {
        $this->getJson('/api/v1/notifications')
            ->assertStatus(401);

        $this->postJson('/api/v1/notifications/some-uuid/read')
            ->assertStatus(401);

        $this->postJson('/api/v1/notifications/read-all')
            ->assertStatus(401);
    }

    public function test_user_can_get_their_own_notifications(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $user->notify(new DummyTestNotification('Judul Notifikasi 1', 'Pesan Notifikasi 1'));

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/notifications');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar notifikasi berhasil diambil.',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    '*' => [
                        'id',
                        'type',
                        'data',
                        'read_at',
                        'is_read',
                        'created_at',
                    ],
                ],
            ]);

        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Judul Notifikasi 1', $response->json('data.0.data.title'));
        $this->assertFalse($response->json('data.0.is_read'));
        $this->assertNull($response->json('data.0.read_at'));
    }

    public function test_user_cannot_see_other_users_notifications(): void
    {
        $user1 = $this->createUser();
        $user2 = $this->createUser();

        $token1 = $user1->createToken('test')->plainTextToken;

        $user1->notify(new DummyTestNotification('Notif User 1', 'Pesan 1'));
        $user2->notify(new DummyTestNotification('Notif User 2', 'Pesan 2'));

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->getJson('/api/v1/notifications');

        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('Notif User 1', $data[0]['data']['title']);

        // Pastikan notifikasi milik user 2 tidak bocor ke user 1
        $notificationUser2 = $user2->notifications()->first();
        $returnedIds = collect($data)->pluck('id')->all();
        $this->assertNotContains($notificationUser2->id, $returnedIds);
    }

    public function test_user_can_mark_their_own_notification_as_read(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $user->notify(new DummyTestNotification);
        $notification = $user->notifications()->first();

        $this->assertNull($notification->read_at);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson("/api/v1/notifications/{$notification->id}/read");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Notifikasi berhasil ditandai sebagai sudah dibaca.',
                'data' => [
                    'id' => $notification->id,
                    'is_read' => true,
                ],
            ]);

        $this->assertNotNull($response->json('data.read_at'));
        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_other_users_notification_cannot_be_marked_as_read(): void
    {
        $user1 = $this->createUser();
        $user2 = $this->createUser();

        $token1 = $user1->createToken('test')->plainTextToken;

        $user2->notify(new DummyTestNotification('Notif Khusus User 2', 'Rahasia'));
        $notificationUser2 = $user2->notifications()->first();

        // User 1 mencoba menandai notifikasi milik User 2
        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->postJson("/api/v1/notifications/{$notificationUser2->id}/read");

        // Tidak boleh membocorkan data dan harus mengembalikan 404
        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan.',
            ]);

        // Notifikasi user 2 tetap belum dibaca
        $this->assertNull($notificationUser2->fresh()->read_at);
    }

    public function test_read_all_only_affects_authenticated_users_notifications(): void
    {
        $user1 = $this->createUser();
        $user2 = $this->createUser();

        $token1 = $user1->createToken('test')->plainTextToken;

        // User 1 punya 2 notifikasi belum dibaca
        $user1->notify(new DummyTestNotification('Notif 1', 'Pesan'));
        $user1->notify(new DummyTestNotification('Notif 2', 'Pesan'));

        // User 2 punya 1 notifikasi belum dibaca
        $user2->notify(new DummyTestNotification('Notif User 2', 'Pesan'));

        $this->assertEquals(2, $user1->unreadNotifications()->count());
        $this->assertEquals(1, $user2->unreadNotifications()->count());

        $response = $this->withHeader('Authorization', 'Bearer '.$token1)
            ->postJson('/api/v1/notifications/read-all');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Semua notifikasi berhasil ditandai sebagai sudah dibaca.',
            ]);

        // Seluruh notifikasi user 1 menjadi read
        $this->assertEquals(0, $user1->fresh()->unreadNotifications()->count());

        // Notifikasi user 2 tetap unread (tidak terpengaruh)
        $this->assertEquals(1, $user2->fresh()->unreadNotifications()->count());
    }
}
