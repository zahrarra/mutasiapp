<?php

namespace App\Notifications;

use App\Models\Mutation;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class MutationStatusChangedNotification extends Notification
{
    use Queueable;

    public function __construct(
        public Mutation $mutation,
        public string $title,
        public string $message,
        public string $action,
        public ?string $status = null
    ) {
        $this->status = $status ?? $mutation->status;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => $this->title,
            'message' => $this->message,
            'mutation_id' => $this->mutation->id,
            'ticket_number' => $this->mutation->ticket_number,
            'status' => $this->status,
            'action' => $this->action,
        ];
    }
}
